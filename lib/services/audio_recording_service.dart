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

@immutable
class AudioRecordingState {
  const AudioRecordingState({
    this.status = AudioRecordingStatus.stopped,
    this.elapsed = Duration.zero,
    this.isInterrupted = false,
    this.hasTake = false,
    this.takeWasEmpty = false,
    this.takeWasInterrupted = false,
    this.microphoneUnavailable = false,
  });

  final AudioRecordingStatus status;

  final Duration elapsed;

  /// Whether this take is paused because the audio system took the microphone,
  /// rather than because the participant chose to stop talking.
  ///
  /// A fact about the take, not about the interruption: it outlives the
  /// interruption itself and only clears when the participant acts — a resume,
  /// a stop, or a fresh take. Clearing it the moment the audio system said the
  /// interruption was over took the notice down while the take was still
  /// sitting there paused, waiting to be resumed.
  final bool isInterrupted;

  final bool hasTake;

  final bool takeWasEmpty;

  /// Whether this finished take was ended by an audio interruption rather than
  /// by the participant. iOS only: see [AudioRecordingService].
  ///
  /// A fact about the finished take, like [takeWasEmpty]. Set together with
  /// [hasTake] and deliberately outlives the stop, so the sheet can say why the
  /// take ended. Cleared by a discard or a fresh take.
  final bool takeWasInterrupted;

  /// Whether the last attempt to start a take was refused because the audio
  /// system would not hand over the microphone, most often because a call
  /// still holds it.
  ///
  /// Nothing was recorded, and the participant can try again once the
  /// microphone is free. Kept apart from [takeWasEmpty] because the cause and
  /// the remedy differ: that take ran and captured nothing, this one never
  /// began. Cleared by the next start attempt or a discard.
  final bool microphoneUnavailable;

  bool get isRecording => status == AudioRecordingStatus.recording;

  bool get isPaused => status == AudioRecordingStatus.paused;

  /// Whether a finished take is sitting on disk waiting to be saved or redone.
  /// Based on [hasTake], not [elapsed]. A take can be stopped before the
  /// elapsed counter's first tick, so using the clock left a real file on disk
  /// with no save button and no way to reach it.
  bool get hasCompletedTake =>
      status == AudioRecordingStatus.stopped && hasTake;

  AudioRecordingState copyWith({
    AudioRecordingStatus? status,
    Duration? elapsed,
    bool? isInterrupted,
    bool? hasTake,
    bool? takeWasEmpty,
    bool? takeWasInterrupted,
    bool? microphoneUnavailable,
  }) {
    return AudioRecordingState(
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      isInterrupted: isInterrupted ?? this.isInterrupted,
      hasTake: hasTake ?? this.hasTake,
      takeWasEmpty: takeWasEmpty ?? this.takeWasEmpty,
      takeWasInterrupted: takeWasInterrupted ?? this.takeWasInterrupted,
      microphoneUnavailable:
          microphoneUnavailable ?? this.microphoneUnavailable,
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
      other.takeWasEmpty == takeWasEmpty &&
      other.takeWasInterrupted == takeWasInterrupted &&
      other.microphoneUnavailable == microphoneUnavailable;

  @override
  int get hashCode => Object.hash(status, elapsed, isInterrupted, hasTake,
      takeWasEmpty, takeWasInterrupted, microphoneUnavailable);
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

typedef RecordingAudioSessionFactory = RecordingAudioSession Function({
  required Future<void> Function(CaptureLoss loss) onCaptureCompromised,
});

/// Captures one diary answer from the microphone.
///
/// Owns everything about a take that is not on screen: the recorder, the
/// wakelock, the elapsed timer, and the file. The audio session and the Android
/// microphone service live in their own classes; this one decides how to react
/// to them, because it is the only thing holding the recorder lock.
///
/// Callers use the intents ([record], [stop], [discardTake], [save]) and render
/// whatever [state] publishes. No UI type reaches this class.
///
/// One instance per answer, on purpose. Two recordings must never share a
/// recorder, a file or a timer. Build it when the recording UI opens and
/// [dispose] it when that UI closes; after that the instance is spent.
///
/// On iOS an audio interruption (Siri, a call, an alarm) ends the take instead
/// of pausing it. flutter_sound records there through one `AVAudioRecorder`,
/// which iOS stops rather than pauses when it interrupts the session, and the
/// plugin never notices. Resuming then calls `record` on a stopped recorder,
/// which erases the file and starts again, so everything said before the
/// interruption was lost. Ending the take keeps it. Android's recorder really
/// does pause, so interruptions there still pause and resume.
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
    RecordingForegroundService? foregroundService,
    RecordingAudioSessionFactory? audioSessionFactory,
  })  : _foregroundService = foregroundService ?? RecordingForegroundService(),
        _audioSessionFactory = audioSessionFactory ?? RecordingAudioSession.new;

  final int promptId;

  final Duration? limit;

  final VoidCallback? onLimitReached;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  final RecordingForegroundService _foregroundService;

  final RecordingAudioSessionFactory _audioSessionFactory;

  late final RecordingAudioSession _audioSession = _audioSessionFactory(
    onCaptureCompromised: _respondToCaptureLoss,
  );

  final ValueNotifier<AudioRecordingState> _state =
      ValueNotifier<AudioRecordingState>(const AudioRecordingState());

  /// The current recorder state, and a listenable for changes to it.
  ValueListenable<AudioRecordingState> get state => _state;

  FlutterSoundRecorder get recorder => _recorder;

  Timer? _timer;

  String? _requestedTakePath;

  String? _takePath;

  bool _recorderBusy = false;

  bool _disposed = false;

  DateTime? _recordingStartedAt;

  static const _minimumRecordingStartDelay = Duration(milliseconds: 400);

  static const _lockPollInterval = Duration(milliseconds: 25);
  static const _lockWaitTimeout = Duration(seconds: 2);

  @visibleForTesting
  static const encoderFlushGrace = Duration(milliseconds: 200);

  /// Opens the recorder and starts listening for audio-system events.
  ///
  /// Failures are reported and swallowed: a recorder that could not be opened
  /// surfaces later as a failed [record], which is where the participant can
  /// actually be told.
  Future<void> initialize() async {
    try {
      _foregroundService.configure();

      await _recorder.openRecorder();

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

  Future<bool> ensureMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> record() async {
    if (_recorderBusy) return;
    _recorderBusy = true;

    try {
      if (_disposed) return;

      // A take waiting to be saved is never recorded over. Redo discards it
      // first; anything else reaching here is a stale tap, and starting a
      // take would write a new file and orphan this one.
      if (_state.value.hasCompletedTake) return;

      if (_recorder.isRecording) {
        await _pauseCapture(failureReason: 'pauseRecorder failed');
      } else if (_recorder.isPaused) {
        await _resumeTake();
      } else {
        await _startTake();
      }
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'record() failed',
      );
    } finally {
      _recorderBusy = false;
    }
  }

  Future<void> _startTake() async {
    _requestedTakePath = null;

    try {
      final path = await _filePath();

      // Before anything is claimed, so a refusal has nothing to undo. On iOS
      // flutter_sound reports a start as successful whether or not the session
      // is active, so going ahead would show "Recording" over silence. Most
      // likely straight after an interruption, while the call that caused it
      // still holds the session.
      if (!await _audioSession.activate()) {
        _emit(
          status: AudioRecordingStatus.stopped,
          elapsed: Duration.zero,
          isInterrupted: false,
          hasTake: false,
          takeWasEmpty: false,
          takeWasInterrupted: false,
          microphoneUnavailable: true,
        );
        return;
      }

      _setWakelock(enable: true);

      await _audioSession.captureInputDevices();
      await _foregroundService.start();
      await _recorder.startRecorder(codec: Codec.aacMP4, toFile: path);
      _requestedTakePath = path;
      _recordingStartedAt = DateTime.now();

      _emit(
        status: AudioRecordingStatus.recording,
        elapsed: Duration.zero,
        isInterrupted: false,
        hasTake: false,
        takeWasEmpty: false,
        takeWasInterrupted: false,
        microphoneUnavailable: false,
      );

      _startTimer();

      await Future<void>.delayed(_minimumRecordingStartDelay);
    } catch (e, s) {
      debugPrint('record() failed: $e');

      CrashlyticsService().recordError(
        e,
        s,
        reason: 'record() failed',
      );

      _setWakelock(enable: false);
      await _foregroundService.stop();
      await _audioSession.deactivate();

      _emit(
        status: AudioRecordingStatus.stopped,
        elapsed: Duration.zero,
        isInterrupted: false,
        hasTake: false,
        takeWasEmpty: false,
        takeWasInterrupted: false,
        microphoneUnavailable: false,
      );
    }
  }

  Future<void> _pauseCapture({
    required String failureReason,
    bool? interrupted,
  }) async {
    _setWakelock(enable: false);

    _timer?.cancel();

    try {
      await _recorder.pauseRecorder();
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: failureReason,
      );
    }

    await _foregroundService.stop();

    _emit(
      status: AudioRecordingStatus.paused,
      isInterrupted: interrupted,
    );
  }

  Future<void> _resumeTake() async {
    // The only place an interrupted take reclaims the session. Nothing does it
    // when the interruption ends, because the take stays paused until here —
    // so the route is re-snapshotted against what is actually plugged in at
    // the moment capture starts again, not at the moment Siri finished.
    //
    // Before anything is claimed. If the session will not come back, a call
    // still holding it, the take stays paused and interrupted: resuming anyway
    // would record silence under "Recording". Android only in practice, since
    // iOS ends an interrupted take rather than pausing it.
    if (_state.value.isInterrupted) {
      if (!await _audioSession.activate()) return;
      await _audioSession.captureInputDevices();
    }

    _setWakelock(enable: true);

    await _foregroundService.start();

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

  Future<bool> stop() async {
    if (_disposed || _recorderBusy) return false;
    _recorderBusy = true;

    try {
      return await _finishTake(interrupted: false);
    } finally {
      _recorderBusy = false;
    }
  }

  /// Ends the live take, recording or paused, and reports whether there is one
  /// to save. The caller holds the recorder lock.
  ///
  /// [interrupted] says the audio system ended it rather than the participant,
  /// and is kept on the finished take as [AudioRecordingState.takeWasInterrupted].
  Future<bool> _finishTake({required bool interrupted}) async {
    final startedAt = _recordingStartedAt;
    if (startedAt == null) return false;

    _timer?.cancel();
    _recordingStartedAt = null;

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

      // flutter_sound reports a failed stop by throwing after it has already
      // marked the recorder stopped. Publishing paused then sent the next tap
      // to a fresh take, which wrote a new file and orphaned this one. So only
      // a recorder that really is still live is left to be stopped again; a
      // stopped one goes on to have its file checked like any other stop.
      if (!_recorder.isStopped) {
        _recordingStartedAt = startedAt;

        _emit(status: AudioRecordingStatus.paused);

        return false;
      }
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

      await _deleteCandidates(reported);

      _takePath = null;
      _requestedTakePath = null;

      // Empty wins over interrupted: there is nothing to save, and that is
      // what the participant needs to hear.
      _emit(
        status: AudioRecordingStatus.stopped,
        elapsed: Duration.zero,
        isInterrupted: false,
        hasTake: false,
        takeWasEmpty: true,
        takeWasInterrupted: false,
      );

      return false;
    }

    _takePath = path;

    _emit(
      status: AudioRecordingStatus.stopped,
      isInterrupted: false,
      hasTake: true,
      takeWasInterrupted: interrupted,
    );

    return true;
  }

  /// Finds the file a finished take is actually in, or `null` if there is not
  /// one.
  ///
  /// [reported] is whatever `stopRecorder()` returned, which is often not a
  /// path: flutter_sound gives `null` on a failed stop and the literal string
  /// `'Recorder is not open'` in some states. So the path we asked it to write
  /// is tried first, and neither name counts until the file has bytes in it.
  ///
  /// Checked here as well as in [save] because [AudioRecordingState.hasTake]
  /// puts the save button on screen, and a take with no file must never reach
  /// it.
  Future<String?> _locateTake(String? reported) async {
    final candidates = _takeCandidates(reported);

    if (candidates.isEmpty) return null;

    for (final candidate in candidates) {
      if (await _isNonEmptyFile(candidate)) return candidate;
    }

    await Future<void>.delayed(encoderFlushGrace);

    for (final candidate in candidates) {
      if (await _isNonEmptyFile(candidate)) return candidate;
    }

    return null;
  }

  /// The files a finished take could be in: the one we asked the recorder to
  /// write, plus [other] — the stop's reported path in [stop], the located take
  /// in [discardTake].
  ///
  /// A set, so the usual case of both naming the same file is handled once.
  /// Neither name is reliably a path, so callers must check the file itself.
  Set<String> _takeCandidates(String? other) {
    final requested = _requestedTakePath;

    return {
      if (requested != null) requested,
      if (other != null) other,
    };
  }

  /// Deletes every file the finished take could be in.
  ///
  /// Both names, not one. When they differ, the other is an empty placeholder
  /// the encoder opened and never wrote to. Safe because every caller has
  /// already decided there is nothing worth keeping, and a name that is not a
  /// real path is a no-op.
  Future<void> _deleteCandidates(String? other) async {
    for (final candidate in _takeCandidates(other)) {
      await _deleteFile(candidate);
    }
  }

  /// Throws away the take just captured, so a fresh [record] starts clean.
  ///
  /// The file is deleted rather than orphaned because the participant has
  /// explicitly rejected it. The path reference is cleared either way, so a
  /// later [save] cannot persist a path that no longer exists.
  Future<void> discardTake() async {
    _timer?.cancel();

    _emit(
      elapsed: Duration.zero,
      hasTake: false,
      takeWasEmpty: false,
      takeWasInterrupted: false,
      microphoneUnavailable: false,
    );

    // The participant has explicitly rejected this take, so nothing it left
    // behind is worth keeping.
    await _deleteCandidates(_takePath);

    _requestedTakePath = null;
    _takePath = null;
  }

  Future<RecordingSaveResult> save() async {
    try {
      _setWakelock(enable: false);
      _timer?.cancel();

      await _foregroundService.stop();

      _emit(status: AudioRecordingStatus.stopped);

      final path = _takePath;
      if (path == null) {
        return const RecordingSaveResult(RecordingSaveOutcome.nothingRecorded);
      }

      if (!await _isNonEmptyFile(path)) {
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

        _emit(
          elapsed: Duration.zero,
          hasTake: false,
          takeWasEmpty: true,
          takeWasInterrupted: false,
        );

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
  /// The fallback for a device where the service could not start. Android then
  /// hands the recorder silence, so pausing is the honest outcome: nothing is
  /// lost and the take can be resumed.
  ///
  /// iOS keeps recording. It declares the `audio` background mode, so capture
  /// really does continue, and pausing would interrupt a take for a glance at
  /// a notification.
  Future<void> handleAppBackgrounded() async {
    if (!Platform.isAndroid) return;

    if (!await _acquireRecorderLock()) return;

    try {
      // Checked once the lock is held, not before: a take still starting reads
      // as not recording, and skipping it then left it capturing silence.
      if (_foregroundService.isActive || !_recorder.isRecording) return;

      await _pauseCapture(
        failureReason: 'pauseRecorder on app background failed',
      );
    } finally {
      _recorderBusy = false;
    }
  }

  /// Reclaims the audio session when the app comes back to the foreground.
  ///
  /// Only for a session this service was actually using. Reactivating every
  /// time would grab exclusive audio focus on every return, so just having the
  /// recording sheet open would stop the participant's music.
  Future<void> handleAppResumed() async {
    if (_disposed) return;
    if (!_recorder.isRecording && !_recorder.isPaused) return;

    await _audioSession.activate();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    _timer?.cancel();
    _audioSession.stopListening();

    // Let an in-flight move finish before teardown touches the audio stack.
    // `_disposed` is already set, so nothing new can claim the recorder. Tearing
    // down on top of a live startRecorder() leaves the file truncated and the
    // native recorder locked. Bounded, so a stuck move cannot block dispose.
    if (!await _waitForRecorderIdle()) {
      CrashlyticsService().recordError(
        StateError('Recorder still busy at dispose'),
        StackTrace.current,
        reason: 'Dispose timed out waiting for the recorder',
      );
    }

    _setWakelock(enable: false);
    await _foregroundService.stop();
    await _audioSession.deactivate();
    await _shutdownRecorder();

    _state.dispose();
  }

  void _emit({
    AudioRecordingStatus? status,
    Duration? elapsed,
    bool? isInterrupted,
    bool? hasTake,
    bool? takeWasEmpty,
    bool? takeWasInterrupted,
    bool? microphoneUnavailable,
  }) {
    if (_disposed) return;

    _state.value = _state.value.copyWith(
      status: status,
      elapsed: elapsed,
      isInterrupted: isInterrupted,
      hasTake: hasTake,
      takeWasEmpty: takeWasEmpty,
      takeWasInterrupted: takeWasInterrupted,
      microphoneUnavailable: microphoneUnavailable,
    );
  }

  /// Holds the screen awake while a take is being captured, and releases it
  /// everywhere capture ends.
  ///
  /// Not awaited on purpose — the caller has nothing to do with the answer —
  /// but the failure is still caught. An unhandled one would be logged as a
  /// *fatal*, so a wakelock hiccup would look like a crash in Crashlytics.
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

  void _startTimer() {
    if (_disposed) return;
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
  /// Teardown is not always a button press — a back gesture, a popped route —
  /// so it can land on a running encoder. Closing one outright leaves the file
  /// truncated and locked; stopping first flushes it to disk. Different from
  /// the wait in [dispose], which lets an in-flight *move* finish.
  ///
  /// The take is not saved, because nothing here has the participant's consent
  /// to keep it, so the file is left on disk unreferenced. No cleanup pass for
  /// those orphans exists yet.
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
  /// lock. Reports false only if the service was disposed while waiting.
  ///
  /// The two kinds of caller differ. [record] and [stop] are taps, and a tap
  /// that lands mid-move is best ignored — the participant can tap again. The
  /// audio-system handlers have nobody to tap again, and dropping their pause
  /// leaves the recorder writing silence, so they queue instead.
  ///
  /// No deadline. Giving up used to publish a pause that never happened, with
  /// the recorder still running under it; every holder releases in `finally`,
  /// and [dispose] ends the wait.
  ///
  /// Polling, not a queue. Several handlers can wait at once (an unplugged
  /// headset reports both "becoming noisy" and a device change), and each
  /// re-reads the recorder once it holds the lock, so the order they win in
  /// does not matter. The claim must happen in the same synchronous step as
  /// the check: split across an `await`, two waiters could both come out
  /// holding it.
  Future<bool> _acquireRecorderLock() async {
    while (!_disposed) {
      if (!_recorderBusy) {
        _recorderBusy = true;
        return true;
      }

      await Future<void>.delayed(_lockPollInterval);
    }

    return false;
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

  /// Whether an audio interruption ends the take rather than pausing it. See
  /// the class doc for why iOS differs. Read off [defaultTargetPlatform] so a
  /// test can override it.
  bool get _interruptionEndsTake => defaultTargetPlatform == TargetPlatform.iOS;

  /// Responds to the audio system taking the route or the focus away from a
  /// take. Driven by [RecordingAudioSession].
  ///
  /// Nothing is checked before the lock is held. A take still starting or
  /// resuming reads as not recording, and bailing out then dropped the
  /// interruption: the take carried on as if nothing had happened.
  Future<void> _respondToCaptureLoss(CaptureLoss loss) async {
    if (!await _acquireRecorderLock()) return;

    try {
      if (loss == CaptureLoss.interruption && _interruptionEndsTake) {
        // A paused take too: resuming it is what would erase the file. Does
        // nothing when no take is live.
        await _finishTake(interrupted: true);
        return;
      }

      if (!_recorder.isRecording) return;

      await _pauseCapture(
        failureReason: 'Failed to pause recorder for audio issue',
        interrupted: true,
      );
    } finally {
      _recorderBusy = false;
    }
  }

  Future<String> _filePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = await Directory(p.join(directory.path, 'audios'))
        .create(recursive: true);
    final now = DateTime.now();
    final fileName = 'audio_prompt_${promptId + 1}_${formatDate(now)}.m4a';
    return p.join(dir.path, fileName);
  }

  /// Whether [path] is a file with bytes in it, as of right now.
  ///
  /// Existence is re-checked on every call, not just length: a stale path that
  /// a redo already deleted must not be resurrected by a retry.
  Future<bool> _isNonEmptyFile(String path) async {
    final file = File(path);

    if (!await file.exists()) return false;

    return await file.length() > 0;
  }

  /// Deletes a take's file if it is still there.
  ///
  /// Failure is logged rather than thrown: a file left behind is untidy, and
  /// nothing the participant does next depends on the disk being clean.
  Future<void> _deleteFile(String? path) async {
    if (path == null) return;

    final file = File(path);

    try {
      if (await file.exists()) await file.delete();
    } catch (e) {
      dev.log('Error deleting file: $e');
    }
  }
}
