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
  });

  final AudioRecordingStatus status;

  final Duration elapsed;

  final bool isInterrupted;

  final bool hasTake;

  final bool takeWasEmpty;

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

typedef RecordingAudioSessionFactory = RecordingAudioSession Function({
  required Future<void> Function() onCaptureCompromised,
  required Future<void> Function() onInterruptionEnded,
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
    onCaptureCompromised: _pauseForAudioIssue,
    onInterruptionEnded: _handleInterruptionEnd,
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

      _setWakelock(enable: true);

      await _audioSession.activate();
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

      _emit(
        status: AudioRecordingStatus.stopped,
        elapsed: Duration.zero,
        isInterrupted: false,
        hasTake: false,
        takeWasEmpty: false,
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
    _setWakelock(enable: true);

    await _foregroundService.start();

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

  Future<bool> stop() async {
    if (_disposed || _recorderBusy) return false;
    _recorderBusy = true;

    try {
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

        _recordingStartedAt = startedAt;

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

        await _deleteCandidates(reported);

        _takePath = null;
        _requestedTakePath = null;

        _emit(
          status: AudioRecordingStatus.stopped,
          elapsed: Duration.zero,
          isInterrupted: false,
          hasTake: false,
          takeWasEmpty: true,
        );

        return false;
      }

      _takePath = path;

      _emit(
        status: AudioRecordingStatus.stopped,
        isInterrupted: false,
        hasTake: true,
      );

      return true;
    } finally {
      _recorderBusy = false;
    }
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

    _emit(elapsed: Duration.zero, hasTake: false, takeWasEmpty: false);

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
  /// The fallback for a device where the service could not start. Android then
  /// hands the recorder silence, so pausing is the honest outcome: nothing is
  /// lost and the take can be resumed.
  ///
  /// iOS keeps recording. It declares the `audio` background mode, so capture
  /// really does continue, and pausing would interrupt a take for a glance at
  /// a notification.
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

      return;
    }

    try {
      if (_disposed || !_recorder.isRecording) return;

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
  /// lock. Reports whether it got it.
  ///
  /// The two kinds of caller differ. [record] and [stop] are taps, and a tap
  /// that lands mid-move is best ignored — the participant can tap again. The
  /// audio-system handlers have nobody to tap again, and dropping their pause
  /// leaves the recorder writing silence, so they queue instead.
  ///
  /// Polling, not a queue, because there is at most one waiter and the wait is
  /// short. The claim must happen in the same synchronous step as the check:
  /// split across an `await`, two waiters could both come out holding it.
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

      _emit(
        status: AudioRecordingStatus.paused,
        isInterrupted: true,
      );
      return;
    }

    try {
      if (_disposed || !_recorder.isRecording) return;
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
