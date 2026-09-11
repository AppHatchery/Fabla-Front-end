import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:audio_diaries_flutter/core/utils/formatter.dart'
    show formatDate;
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/recording_audio_session.dart';
import 'package:audio_diaries_flutter/services/recording_foreground_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// An immutable snapshot of the recorder, published through
/// [AudioRecordingService.state].
///
/// Holds only what a caller cannot derive for itself. The elapsed time is a
/// [Duration] rather than a formatted string so that formatting stays a
/// presentation concern.
@immutable
class AudioRecordingState {
  const AudioRecordingState({
    this.status = AudioRecordingStatus.stopped,
    this.elapsed = Duration.zero,
    this.isInterrupted = false,
    this.hasTake = false,
    this.takeWasEmpty = false,
  });

  final AudioRecordingStatus status;

  /// How much audio the current take has captured.
  ///
  /// Advances on a one-second tick, so it is a display counter and not a
  /// measure of the take — a take shorter than a second reads as zero here
  /// while still being a real file on disk. See [hasTake].
  final Duration elapsed;

  /// Whether the last pause was forced by the audio system — a phone call, a
  /// headset switching off — rather than by the participant.
  final bool isInterrupted;

  /// Whether the recorder has produced a file for the current take.
  ///
  /// Set when a stop finds a file with bytes in it, cleared when that file is
  /// discarded or rejected, so it tracks the file rather than the clock.
  final bool hasTake;

  /// Whether the take that just ended captured no audio at all.
  ///
  /// Distinct from `!hasTake`, which is also true before anything has been
  /// recorded. This says a take ran and came back with nothing — the one
  /// outcome the participant cannot diagnose from the controls, because the
  /// sheet resets to 00:00 exactly as if the stop had never registered.
  /// Cleared as soon as a fresh take starts.
  final bool takeWasEmpty;

  bool get isRecording => status == AudioRecordingStatus.recording;

  bool get isPaused => status == AudioRecordingStatus.paused;

  /// Whether a finished take is sitting on disk waiting to be saved or redone.
  ///
  /// Driven by [hasTake] rather than [elapsed]: stopping is allowed from
  /// [AudioRecordingService._minimumRecordingStartDelay], which is shorter
  /// than the first tick of the elapsed counter, so gating on the clock left
  /// a take stopped inside that window with a file on disk, no save control,
  /// and no way to reach it.
  bool get hasCompletedTake =>
      status == AudioRecordingStatus.stopped && hasTake;

  AudioRecordingState copyWith({
    AudioRecordingStatus? status,
    Duration? elapsed,
    bool? isInterrupted,
    bool? hasTake,
    bool? takeWasEmpty,
  }) {
    return AudioRecordingState(
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      isInterrupted: isInterrupted ?? this.isInterrupted,
      hasTake: hasTake ?? this.hasTake,
      takeWasEmpty: takeWasEmpty ?? this.takeWasEmpty,
    );
  }

  // Value equality is what lets ValueNotifier drop a no-op publish, so a
  // handler that re-asserts the state the recorder is already in does not
  // rebuild the UI.
  @override
  bool operator ==(Object other) =>
      other is AudioRecordingState &&
      other.status == status &&
      other.elapsed == elapsed &&
      other.isInterrupted == isInterrupted &&
      other.hasTake == hasTake &&
      other.takeWasEmpty == takeWasEmpty;

  @override
  int get hashCode =>
      Object.hash(status, elapsed, isInterrupted, hasTake, takeWasEmpty);
}

/// The outcome of a save attempt, plus the file it produced.
@immutable
class RecordingSaveResult {
  const RecordingSaveResult(this.outcome, [this.path]);

  final RecordingSaveOutcome outcome;

  /// Absolute path of the captured audio. Non-null only when [outcome] is
  /// [RecordingSaveOutcome.saved].
  final String? path;
}

/// Captures one diary answer from the microphone.
///
/// Owns everything about a take that is not on screen: the flutter_sound
/// recorder, the screen wakelock, the elapsed-time timer, and the file the
/// take is written to. The audio session and the Android microphone foreground
/// service are delegated to [RecordingAudioSession] and
/// [RecordingForegroundService]; this class is what decides how to react to
/// them, because it is the only thing holding the recorder lock.
///
/// Callers drive it with intents ([record], [stop], [discardTake], [save]) and
/// render whatever [state] publishes; no UI type reaches this class.
///
/// One instance captures one answer. It is deliberately not a singleton: two
/// recordings must never share a recorder, a temp file, or a timer, and a
/// long-lived instance would keep the audio session open between answers.
/// Construct it when the recording UI opens and [dispose] it when that UI goes
/// away — after [dispose] the instance is spent and cannot record again.
///
/// ```dart
/// final service = AudioRecordingService(promptId: 0, limit: limit);
/// await service.initialize();
/// if (await service.ensureMicrophonePermission()) await service.record();
/// ```
class AudioRecordingService {
  AudioRecordingService({
    required this.promptId,
    this.limit,
    this.onLimitReached,
  });

  /// Zero-based index of the prompt being answered. Used to name the audio
  /// file and to tag error reports.
  final int promptId;

  /// Hard cap on a take. When reached the recorder stops itself and
  /// [onLimitReached] fires. `null` — or a zero duration — means no cap.
  final Duration? limit;

  /// Called once [limit] has been reached *and* the recorder actually stopped.
  ///
  /// Gated on the stop succeeding because the alternative is a take that
  /// reports itself finished with no file behind it. Saving is not done here:
  /// persisting an answer and closing the UI belong to the caller.
  final VoidCallback? onLimitReached;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  final RecordingForegroundService _foregroundService =
      RecordingForegroundService();

  late final RecordingAudioSession _audioSession = RecordingAudioSession(
    onCaptureCompromised: _pauseForAudioIssue,
    onInterruptionEnded: _handleInterruptionEnd,
  );

  final ValueNotifier<AudioRecordingState> _state =
      ValueNotifier<AudioRecordingState>(const AudioRecordingState());

  /// The current recorder state, and a listenable for changes to it.
  ValueListenable<AudioRecordingState> get state => _state;

  /// The recorder behind this service, exposed only so a waveform widget can
  /// subscribe to its progress stream. Nothing else should touch it: every
  /// transition runs through the intents on this class, which keep the
  /// wakelock, the foreground service, and [state] in step.
  FlutterSoundRecorder get recorder => _recorder;

  Timer? _timer;

  /// The file [record] asked `startRecorder()` to write.
  String? _requestedTakePath;

  /// The file a finished take is actually sitting in. See [_locateTake].
  String? _takePath;

  /// Held while a start, pause, resume or stop is in flight.
  ///
  /// [record] and [stop] drive the same recorder from controls sitting side by
  /// side, so a tap on one while the other is awaiting would put two calls on
  /// it at once. First in wins; the other is ignored.
  bool _recorderBusy = false;

  bool _disposed = false;

  DateTime? _recordingStartedAt;

  /// How long [record] holds the lock past `startRecorder()`, and the age a
  /// take has to reach before [stop] will touch it. One constant for both:
  /// they are the same window seen from either end.
  static const _minimumRecordingStartDelay = Duration(milliseconds: 400);

  /// How often [_acquireRecorderLock] re-checks for a free recorder, and how
  /// long it keeps trying.
  ///
  /// The timeout is generous next to what it waits on — the longest transition
  /// is a fresh start — because giving up early is the failure that costs a
  /// recording, and giving up late costs a handler a few hundred milliseconds
  /// it was going to spend waiting anyway.
  static const _lockPollInterval = Duration(milliseconds: 25);
  static const _lockWaitTimeout = Duration(seconds: 2);

  /// Opens the recorder and starts listening for audio-system events.
  ///
  /// Failures are reported and swallowed: a recorder that could not be opened
  /// surfaces later as a failed [record], which is where the participant can
  /// actually be told.
  Future<void> initialize() async {
    try {
      _foregroundService.configure();

      await _recorder.openRecorder();

      // Before the audio session, not after. flutter_sound's default
      // subscription duration is zero, which it documents as "no callbacks" —
      // so leaving this behind a call that can throw means one audio-session
      // failure silently costs the waveform every level for the whole
      // session, with nothing but an unrelated Crashlytics entry to show why.
      await _recorder.setSubscriptionDuration(
        const Duration(milliseconds: 150),
      );

      await _audioSession.startListening();
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'recorderInit failed',
      );
    }
  }

  /// Asks for the microphone, reporting whether it was granted.
  ///
  /// Separate from [record] so the caller owns what a refusal looks like — a
  /// permission sheet, an error, nothing at all — instead of this class
  /// deciding for it.
  Future<bool> ensureMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Starts, pauses, or resumes a take, depending on what the recorder is
  /// already doing.
  ///
  /// One entry point rather than three because it backs a single control, and
  /// because the re-entrancy guard has to cover all three transitions: a
  /// double tap that started and then paused a take would otherwise leave the
  /// UI and the encoder disagreeing.
  ///
  /// Each transition recovers on its own terms — see [_startTake],
  /// [_pauseTake] and [_resumeTake]. A single catch across all three cannot:
  /// what is honest after a failed start (nothing is recording) is a lie after
  /// a failed pause (the encoder is still running).
  ///
  /// The caller must have secured the microphone first — see
  /// [ensureMicrophonePermission].
  Future<void> record() async {
    if (_recorderBusy) return;
    _recorderBusy = true;

    try {
      if (_disposed) return;

      if (_recorder.isRecording) {
        await _pauseTake();
      } else if (_recorder.isPaused) {
        await _resumeTake();
      } else {
        await _startTake();
      }
    } finally {
      _recorderBusy = false;
    }
  }

  /// Begins a fresh take.
  ///
  /// On failure nothing is capturing, so the recovery is a clean slate: the
  /// wakelock and the service are released and the state goes back to where a
  /// first tap would find it.
  Future<void> _startTake() async {
    try {
      final path = await _filePath();

      _setWakelock(enable: true);

      // Failure does not abort the take: a degraded recording still beats
      // none.
      await _audioSession.activate();
      await _audioSession.captureInputDevices();

      // Before startRecorder(), so the microphone is already protected by the
      // time anything is being written. Failure here means the take is
      // foreground-only, which is what handleAppBackgrounded() falls back on.
      await _foregroundService.start();

      await _recorder.startRecorder(codec: Codec.aacMP4, toFile: path);

      _requestedTakePath = path;
      _recordingStartedAt = DateTime.now();

      // The clock is reset here, not only in discardTake(): a take started to
      // recover from a failed stop would otherwise inherit the previous one's
      // elapsed count, which drives both the progress bar and the [limit]
      // auto-stop — so the replacement take would be cut short by however long
      // the failed one ran.
      _emit(
        status: AudioRecordingStatus.recording,
        elapsed: Duration.zero,
        hasTake: false,
        takeWasEmpty: false,
      );

      _startTimer();

      // Holds the lock past the start so a stop cannot land on a recorder that
      // has not finished opening the file.
      await Future<void>.delayed(_minimumRecordingStartDelay);
    } catch (e, s) {
      debugPrint('record() failed: $e');

      CrashlyticsService().recordError(
        e,
        s,
        reason: 'record() failed',
      );

      // Both taken above, so a throw after either would otherwise hold the
      // screen awake and leave a microphone notification claiming a recording
      // that never began.
      _setWakelock(enable: false);
      await _foregroundService.stop();

      _emit(
        status: AudioRecordingStatus.stopped,
        elapsed: Duration.zero,
        hasTake: false,
      );
    }
  }

  /// Pauses a live take.
  ///
  /// Paused is published whether or not the pause landed. The timer is already
  /// cancelled by then, so leaving the state on recording would freeze the
  /// elapsed count, kill the [limit] auto-stop, and show a stopped clock under
  /// a "Recording" header.
  Future<void> _pauseTake() async {
    _setWakelock(enable: false);
    _timer?.cancel();

    try {
      await _recorder.pauseRecorder();
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'pauseRecorder failed',
      );
    }

    // After the pause, not before: dropping the service while the encoder is
    // still writing opens a window where a background switch costs Android the
    // microphone. Nothing is being captured once paused, so the service — and
    // the notification announcing it — should not be up either.
    await _foregroundService.stop();

    _emit(status: AudioRecordingStatus.paused);
  }

  /// Resumes a paused take.
  ///
  /// On failure the recorder is still paused, so the state stays paused and
  /// the resume control stays on screen. Reporting stopped instead would put
  /// the UI back on a bare mic button, hiding both the stop and the resume for
  /// a take still sitting in the encoder.
  Future<void> _resumeTake() async {
    _setWakelock(enable: true);

    // Started here as well as on a fresh take: this tap is a foreground
    // moment, and Android 12+ will not let the service start later.
    await _foregroundService.start();

    // Resuming out of an audio issue: the session may have been deactivated
    // and the route replaced under us, so both are reclaimed before the
    // encoder writes again. A device removal has no interruption-end event, so
    // this is also the only place that can clear the banner — without it the
    // header stays on "Recording Interrupted" for the rest of the take.
    if (_state.value.isInterrupted) {
      await _audioSession.activate();
      await _audioSession.captureInputDevices();
    }

    try {
      await _recorder.resumeRecorder();
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'resumeRecorder failed',
      );

      _setWakelock(enable: false);
      await _foregroundService.stop();

      _emit(status: AudioRecordingStatus.paused);
      return;
    }

    _emit(
      status: AudioRecordingStatus.recording,
      isInterrupted: false,
    );

    _startTimer();
  }

  /// Ends the take, reporting whether it produced a file.
  ///
  /// The return value is what the [limit] timer gates [onLimitReached] on, and
  /// what a caller should gate a [save] on: a stop with nothing behind it
  /// leaves no file to persist.
  Future<bool> stop() async {
    if (_disposed || _recorderBusy) return false;
    _recorderBusy = true;

    try {
      final startedAt = _recordingStartedAt;
      if (startedAt == null) return false;

      if (DateTime.now().difference(startedAt) < _minimumRecordingStartDelay) {
        return false;
      }

      // Cancelled before the call, not after: a throw below would otherwise
      // leave the limit branch of _startTimer() re-firing stop() every second.
      _timer?.cancel();
      _recordingStartedAt = null;

      // Released either way: no branch below leaves this service capturing,
      // and closing the UI is allowed as soon as recording has ended.
      _setWakelock(enable: false);
      await _foregroundService.stop();

      String? reported;
      try {
        reported = await _recorder.stopRecorder();
      } catch (e, s) {
        CrashlyticsService().recordError(
          e,
          s,
          reason: 'stopRecorder failed',
        );

        // Re-armed so the stop control keeps working. Left null, every later
        // tap returns at the guard above and hasCompletedTake never turns
        // true, so neither stop nor save is reachable again and the take is
        // lost.
        _recordingStartedAt = startedAt;

        // The recorder may well still be running, so paused is the honest
        // state and it keeps stop on screen for a retry.
        _emit(status: AudioRecordingStatus.paused);

        return false;
      }

      final path = await _locateTake(reported);

      if (path == null) {
        CrashlyticsService().recordError(
          StateError('stopRecorder produced no usable file'),
          StackTrace.current,
          reason: 'stopRecorder produced no file',
          context: {
            'prompt_id': promptId,
            'reported_path': reported ?? 'null',
          },
        );

        // Unlike the catch above, the recorder did stop — it just has nothing
        // to show for it. So this take is over rather than resumable, and a
        // clean slate is the only thing the participant can act on. Reporting
        // paused here would offer a stop control that can never succeed.
        //
        // takeWasEmpty is what stops that slate being silent: the sheet resets
        // to 00:00, which on its own reads as a tap that did not register, so
        // the participant records the same answer again and loses it the same
        // way. The caller renders it; this class only reports it.
        _takePath = null;
        _requestedTakePath = null;

        _emit(
          status: AudioRecordingStatus.stopped,
          elapsed: Duration.zero,
          hasTake: false,
          takeWasEmpty: true,
        );

        return false;
      }

      _takePath = path;
      _emit(status: AudioRecordingStatus.stopped, hasTake: true);

      return true;
    } finally {
      _recorderBusy = false;
    }
  }

  /// Finds the file a finished take is actually in, or `null` if there is not
  /// one.
  ///
  /// [reported] is whatever `stopRecorder()` handed back, which is not
  /// reliably a path: flutter_sound returns `null` when the native stop failed
  /// and the literal string `'Recorder is not open'` when the recorder was
  /// never opened. So the path this service asked `startRecorder()` to write
  /// is tried first, and [reported] only as a fallback — and neither counts
  /// until it points at a file with bytes in it.
  ///
  /// Checked here as well as in [save] because [AudioRecordingState.hasTake]
  /// is what puts the save control on screen. A take with no file behind it
  /// must not reach it, or the participant confirms a finished-looking take
  /// and nothing happens.
  Future<String?> _locateTake(String? reported) async {
    // A set, so the usual case where both name the same file is only checked
    // once — [_hasValidAudioFile] waits out a late flush before giving up.
    for (final candidate in {_requestedTakePath, reported}) {
      if (candidate != null && await _hasValidAudioFile(candidate)) {
        return candidate;
      }
    }

    return null;
  }

  /// Throws away the take just captured, so a fresh [record] starts clean.
  ///
  /// The file is deleted rather than orphaned because the participant has
  /// explicitly rejected it. The path reference is cleared either way, so a
  /// later [save] cannot persist a path that no longer exists.
  Future<void> discardTake() async {
    _timer?.cancel();

    _emit(elapsed: Duration.zero, hasTake: false, takeWasEmpty: false);

    final path = _takePath;
    _requestedTakePath = null;
    if (path == null) return;

    final file = File(path);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (e) {
        dev.log("Error deleting file: $e");
      }
    }

    _takePath = null;
  }

  /// Validates the take and hands back the file to persist.
  ///
  /// flutter_sound creates the file lazily on the first audio write, so an
  /// inactive audio session leaves a valid-looking path pointing at nothing.
  /// Persisting that path would create a database row for audio that does not
  /// exist, which then fails silently on both playback and S3 upload while the
  /// submission still reaches DynamoDB. [stop] already applies this gate, so
  /// reaching it here means the file went away in between — a redo, a cleanup,
  /// a device running out of space.
  ///
  /// Writing the answer away and closing the UI stay with the caller: this
  /// class knows about audio, not about the diary it belongs to.
  Future<RecordingSaveResult> save() async {
    try {
      _setWakelock(enable: false);
      _timer?.cancel();

      // Normally already down via stop(), but save() is also the confirm
      // control's handler and the timer-limit path, so it releases the service
      // itself rather than trusting the order it was reached in. After the
      // cancel above, so no tick can land in the gap.
      await _foregroundService.stop();

      _emit(status: AudioRecordingStatus.stopped);

      final path = _takePath;
      if (path == null) {
        return const RecordingSaveResult(RecordingSaveOutcome.nothingRecorded);
      }

      if (!await _hasValidAudioFile(path)) {
        _takePath = null;

        await CrashlyticsService().recordError(
          FileSystemException(
            'Recorder produced no audio file',
            path,
          ),
          StackTrace.current,
          reason: 'save() aborted - empty recording',
          context: {
            'prompt_id': promptId,
          },
        );

        // Same failure the stop gate reports, reached from the other side: the
        // file was there when the take ended and is not there now. The
        // participant sees the same banner either way.
        _emit(elapsed: Duration.zero, hasTake: false, takeWasEmpty: true);

        return const RecordingSaveResult(RecordingSaveOutcome.emptyFile);
      }

      return RecordingSaveResult(RecordingSaveOutcome.saved, path);
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'save() failed',
      );

      return const RecordingSaveResult(RecordingSaveOutcome.failed);
    }
  }

  /// Pauses a live recording when the app goes to the background and the
  /// foreground service is not there to protect it.
  ///
  /// This is the fallback for a device where the service failed to start —
  /// permissions refused, an OEM restriction, a stop that did not take. In
  /// that state Android hands the recorder silence, so pausing is the honest
  /// outcome: nothing is lost and the take can be resumed.
  ///
  /// iOS is left recording. It declares the `audio` background mode, so
  /// capture genuinely continues there, and pausing would interrupt a take for
  /// a glance at a notification.
  Future<void> handleAppBackgrounded() async {
    if (!Platform.isAndroid ||
        _foregroundService.isActive ||
        !_recorder.isRecording) {
      return;
    }

    if (!await _acquireRecorderLock()) {
      CrashlyticsService().recordError(
        StateError('Recorder still busy when backgrounding needed a pause'),
        StackTrace.current,
        reason: 'App background pause timed out waiting for the recorder',
      );

      // Nothing published here, unlike _pauseForAudioIssue(). The screen is
      // going away, so there is no one to inform, and claiming paused over a
      // stop that was in the middle of finishing would hide the save control
      // on a real take for no gain.
      return;
    }

    try {
      // Re-checked after the wait: the transition we queued behind may have
      // stopped or paused the take already.
      if (_disposed || !_recorder.isRecording) return;

      _setWakelock(enable: false);
      _timer?.cancel();

      try {
        await _recorder.pauseRecorder();
      } catch (e, s) {
        CrashlyticsService().recordError(
          e,
          s,
          reason: 'pauseRecorder on app background failed',
        );
      }

      // Outside the inner try: the timer above is already cancelled, so
      // leaving this on recording would freeze the elapsed count and kill the
      // [limit] auto-stop.
      _emit(status: AudioRecordingStatus.paused);
    } finally {
      _recorderBusy = false;
    }
  }

  /// Reclaims the audio session when the app comes back to the foreground.
  ///
  /// Only ever for a session this service was actually using. Reactivating
  /// unconditionally claims exclusive audio focus on every return to the
  /// foreground, so merely having the recording UI open and glancing at
  /// another app would stop the participant's music for a recording that never
  /// started.
  Future<void> handleAppResumed() async {
    if (_disposed) return;
    if (!_recorder.isRecording && !_recorder.isPaused) return;

    await _audioSession.activate();
  }

  /// Releases the microphone, the audio session, the wakelock and the
  /// foreground service. The instance cannot record after this.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    _timer?.cancel();
    _audioSession.stopListening();

    // Waits out a transition still in flight before any of the teardown below
    // touches the audio stack. `_disposed` is already set, so nothing new can
    // claim the recorder while we wait — this is only about letting the
    // current call finish. Tearing down on top of a live startRecorder()
    // deactivates the session and closes the recorder underneath it, which is
    // what leaves a file truncated and the native recorder locked.
    //
    // Bounded, because a transition that never returns must not keep the
    // service alive.
    if (!await _waitForRecorderIdle()) {
      CrashlyticsService().recordError(
        StateError('Recorder still busy at dispose'),
        StackTrace.current,
        reason: 'Dispose timed out waiting for the recorder',
      );
    }

    // The recording UI can be torn down without either control being tapped —
    // a system back gesture, a route pop — so the lock and the audio focus are
    // released here rather than only in stop()/save().
    _setWakelock(enable: false);
    await _foregroundService.stop();
    await _audioSession.deactivate();
    await _shutdownRecorder();

    _state.dispose();
  }

  /// Publishes a new state, unless this service is already spent.
  ///
  /// The guard is what the `mounted` checks around every `setState` used to
  /// be: handlers here await platform calls and can land after teardown, and
  /// a [ValueNotifier] throws once disposed.
  void _emit({
    AudioRecordingStatus? status,
    Duration? elapsed,
    bool? isInterrupted,
    bool? hasTake,
    bool? takeWasEmpty,
  }) {
    if (_disposed) return;

    _state.value = _state.value.copyWith(
      status: status,
      elapsed: elapsed,
      isInterrupted: isInterrupted,
      hasTake: hasTake,
      takeWasEmpty: takeWasEmpty,
    );
  }

  /// Holds the screen awake while a take is being captured, and releases it
  /// everywhere capture ends.
  ///
  /// Deliberately not awaited — the caller is mid-transition and has nothing
  /// to do with the answer — but the failure is caught rather than left to
  /// reject. An unhandled rejection reaches `PlatformDispatcher.onError`,
  /// which reports it as a *fatal*, so an OEM wakelock hiccup would show up in
  /// Crashlytics as a crash.
  void _setWakelock({required bool enable}) =>
      unawaited(_toggleWakelock(enable: enable));

  Future<void> _toggleWakelock({required bool enable}) async {
    try {
      await WakelockPlus.toggle(enable: enable);
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Wakelock toggle failed',
      );
    }
  }

  /// Ticks the elapsed count, and stops the take once [limit] is reached.
  void _startTimer() {
    // Every caller cancels first, but two live periodic timers would double
    // the clock and there is no way back from that.
    _timer?.cancel();

    final effectiveLimit =
        (limit != null && limit!.inSeconds > 0) ? limit! : null;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (effectiveLimit != null && _state.value.elapsed >= effectiveLimit) {
        final stopped = await stop();

        if (stopped && !_disposed) {
          onLimitReached?.call();
        }

        return;
      }

      _emit(elapsed: _state.value.elapsed + const Duration(seconds: 1));
    });
  }

  /// Ends any live take before closing the recorder.
  ///
  /// Teardown is not always driven by a control — an Android back gesture, a
  /// route popped from a notification tap — so disposal can land on a running
  /// encoder. Closing one outright races it, leaving the file truncated and
  /// locked; stopping first flushes what was captured to disk. Distinct from
  /// the wait in [dispose]: that one lets an in-flight *transition* finish,
  /// this one ends a take that is simply still running.
  ///
  /// The take is not saved — nothing here has the participant's consent to
  /// persist it — so the file is left on disk unreferenced. Reclaiming those
  /// orphans is a separate job; no cleanup pass exists yet.
  Future<void> _shutdownRecorder() async {
    try {
      if (_recorder.isRecording || _recorder.isPaused) {
        await _recorder.stopRecorder();
      }
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'stopRecorder during dispose failed',
      );
    }

    try {
      await _recorder.closeRecorder();
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'closeRecorder during dispose failed',
      );
    }
  }

  /// Waits for any in-flight transition to finish, then takes the recorder
  /// lock. Reports whether it got it.
  ///
  /// This is the difference between the two kinds of caller. [record] and
  /// [stop] are taps, and a tap that arrives mid-transition is best ignored —
  /// the participant can simply tap again. The audio-system handlers have no
  /// one to tap again: dropping their pause leaves the recorder writing into a
  /// session that has already been taken away, and the resulting silence is
  /// indistinguishable downstream from a participant who said nothing. So they
  /// queue behind the transition instead of giving up on it.
  ///
  /// Polling rather than a queue because there is at most one waiter and the
  /// wait is short. The claim has to happen in the same synchronous step as
  /// the check that the recorder is free: split the two across an `await` and
  /// two waiters whose polls resolve in the same microtask batch both come out
  /// of it holding the lock.
  Future<bool> _acquireRecorderLock() async {
    final deadline = DateTime.now().add(_lockWaitTimeout);

    while (true) {
      if (_disposed) return false;

      if (!_recorderBusy) {
        _recorderBusy = true;
        return true;
      }

      if (DateTime.now().isAfter(deadline)) return false;

      await Future<void>.delayed(_lockPollInterval);
    }
  }

  /// Waits out an in-flight transition without claiming the recorder. Reports
  /// whether it came free.
  ///
  /// Only [dispose] wants this: it has nothing to claim the lock for, and
  /// unlike a handler waiting its turn it cannot abandon the wait once
  /// `_disposed` is set — it *is* the teardown.
  Future<bool> _waitForRecorderIdle() async {
    final deadline = DateTime.now().add(_lockWaitTimeout);

    while (_recorderBusy) {
      if (DateTime.now().isAfter(deadline)) return false;

      await Future<void>.delayed(_lockPollInterval);
    }

    return true;
  }

  /// Clears the interrupted banner once the audio system says the interruption
  /// is over. Driven by [RecordingAudioSession].
  Future<void> _handleInterruptionEnd() async {
    if (_disposed || !_state.value.isInterrupted) return;

    // Stay interrupted when the session could not be revived.
    if (!await _audioSession.activate()) return;

    _emit(isInterrupted: false);
  }

  /// Pauses a take the audio system has taken the route or the focus away
  /// from. Driven by [RecordingAudioSession].
  Future<void> _pauseForAudioIssue() async {
    if (_disposed || !_recorder.isRecording) return;

    if (!await _acquireRecorderLock()) {
      CrashlyticsService().recordError(
        StateError('Recorder still busy when an audio issue needed a pause'),
        StackTrace.current,
        reason: 'Audio issue pause timed out waiting for the recorder',
      );

      // Published anyway. Capture cannot be trusted whether or not the pause
      // landed, and the participant should see that rather than a running
      // timer. Whatever holds the lock publishes its own outcome after this,
      // so a transition that was genuinely finishing still gets the last word.
      _emit(
        status: AudioRecordingStatus.paused,
        isInterrupted: true,
      );
      return;
    }

    try {
      // Re-checked after the wait: whatever held the lock may have stopped the
      // take outright, and publishing paused over a finished one would take
      // the save control away from a take that is already on disk.
      if (_disposed || !_recorder.isRecording) return;

      _setWakelock(enable: false);

      // Cancelled before the first await: a tick landing in that window could
      // reach the limit branch, run stop() to completion, and then have its
      // stopped status overwritten by the paused below — hiding the save
      // control on a take that had in fact finished.
      _timer?.cancel();
      await _foregroundService.stop();

      try {
        await _recorder.pauseRecorder();
      } catch (e, s) {
        CrashlyticsService().recordError(
          e,
          s,
          reason: 'Failed to pause recorder for audio issue',
        );
      }

      // Outside the inner try, so a failed pause still moves the UI: the route
      // or the focus is gone either way, which means whatever the encoder is
      // still writing cannot be trusted.
      _emit(
        status: AudioRecordingStatus.paused,
        isInterrupted: true,
      );
    } finally {
      _recorderBusy = false;
    }
  }

  /// Where the next take is written:
  /// `<documents>/audios/audio_prompt_N_<date>.m4a`.
  Future<String> _filePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = await Directory(p.join(directory.path, 'audios'))
        .create(recursive: true);
    final now = DateTime.now();
    final fileName = 'audio_prompt_${promptId + 1}_${formatDate(now)}.m4a';
    return p.join(dir.path, fileName);
  }

  /// Whether [path] is a take rather than an empty placeholder.
  ///
  /// The encoder can still be flushing when `stopRecorder()` returns, so a
  /// file that is empty on the first look is given one more chance. The second
  /// look re-checks existence, not just length: a stale path that a redo
  /// already deleted must not be resurrected by the retry.
  Future<bool> _hasValidAudioFile(String path) async {
    final file = File(path);

    if (!await file.exists()) return false;

    var length = await file.length();
    if (length > 0) return true;

    await Future<void>.delayed(const Duration(milliseconds: 200));

    if (!await file.exists()) return false;

    length = await file.length();

    return length > 0;
  }
}
