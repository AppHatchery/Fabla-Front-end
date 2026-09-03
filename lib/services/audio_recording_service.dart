import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:audio_diaries_flutter/core/utils/formatter.dart'
    show formatDate;
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
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
  });

  final AudioRecordingStatus status;

  /// How much audio the current take has captured.
  final Duration elapsed;

  /// Whether the last pause was forced by the audio system — a phone call, a
  /// headset switching off — rather than by the participant.
  final bool isInterrupted;

  bool get isRecording => status == AudioRecordingStatus.recording;

  bool get isPaused => status == AudioRecordingStatus.paused;

  /// Whether a finished take is sitting on disk waiting to be saved or redone.
  bool get hasCompletedTake =>
      status == AudioRecordingStatus.stopped && elapsed.inSeconds > 0;

  AudioRecordingState copyWith({
    AudioRecordingStatus? status,
    Duration? elapsed,
    bool? isInterrupted,
  }) {
    return AudioRecordingState(
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      isInterrupted: isInterrupted ?? this.isInterrupted,
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
      other.isInterrupted == isInterrupted;

  @override
  int get hashCode => Object.hash(status, elapsed, isInterrupted);
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
/// recorder, the audio session and its interruption handling, the Android
/// microphone foreground service, the screen wakelock, the elapsed-time timer,
/// and the file the take is written to. Callers drive it with intents
/// ([record], [stop], [discardTake], [save]) and render whatever
/// [state] publishes; no UI type reaches this class.
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
  /// persisting an answer and closing the UI belong to the caller, so it is
  /// handed the moment instead.
  final VoidCallback? onLimitReached;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

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

  /// Absolute path of the take on disk, set once the recorder has stopped.
  String? _takePath;

  /// Serialises taps on the record control: without them a double tap can
  /// interleave a start with a pause.
  bool _recordingCheck = false;
  bool _recordingTransitioning = false;

  bool _disposed = false;

  //interruption
  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;
  StreamSubscription<AudioDevicesChangedEvent>? _devicesChangedSubscription;

  /// Fires when the route the recording was using disappears — a Bluetooth
  /// headset switched off, a wired mic unplugged.
  ///
  /// [_handleAudioDevicesChanged] cannot be relied on for this. On iOS
  /// audio_session derives that event by diffing the current route against the
  /// previous one, and the previous one defaults to the current route until a
  /// route change has already been seen. Since [AudioSession.instance] is
  /// first created here, in [initialize], a headset paired before the recorder
  /// opened makes its disconnect the very first route change — diffed against
  /// itself, so `devicesRemoved` arrives empty and nothing pauses. This stream
  /// is emitted straight off the `oldDeviceUnavailable` notification with no
  /// diffing, so it fires the first time too.
  StreamSubscription<void>? _becomingNoisySubscription;

  /// Ids of the input devices present when the current recording started,
  /// matched against later removals to detect a route loss mid-recording.
  final Set<String> _inputDeviceIds = {};

  DateTime? _recordingStartedAt;

  static const _minimumRecordingStartDelay = Duration(
    milliseconds: 400,
  );

  /// Whether the microphone foreground service is currently running.
  ///
  /// Kept in step with "a take is being captured": started on the tap that
  /// begins or resumes one, stopped everywhere capture ends. It is also what
  /// [handleAppBackgrounded] reads to decide whether backgrounding is safe.
  bool _foregroundServiceActive = false;

  /// Notification id for the recording service. Distinct from the ids the
  /// alarm and reminder notifications use so it cannot replace one of theirs.
  static const _recordingServiceId = 8291;

  /// Opens the recorder and starts listening for audio-system events.
  ///
  /// Failures are reported and swallowed: a recorder that could not be opened
  /// surfaces later as a failed [record], which is where the participant can
  /// actually be told.
  Future<void> initialize() async {
    try {
      _initForegroundTask();

      await _recorder.openRecorder();

      final session = await _configureAudioSession();

      _interruptionSubscription ??= session.interruptionEventStream.listen(
        _handleAudioInterruption,
      );

      _devicesChangedSubscription ??= session.devicesChangedEventStream.listen(
        _handleAudioDevicesChanged,
      );

      // Fire-and-forget on purpose: the listener signature is synchronous, and
      // _pauseForAudioIssue() reports its own failures rather than throwing,
      // so nothing can escape into PlatformDispatcher.onError as a fatal.
      _becomingNoisySubscription ??= session.becomingNoisyEventStream.listen(
        (_) => unawaited(_pauseForAudioIssue()),
      );

      await _recorder.setSubscriptionDuration(
        const Duration(milliseconds: 150),
      );
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
  /// The caller must have secured the microphone first — see
  /// [ensureMicrophonePermission].
  Future<void> record() async {
    //if recording is active return
    if (_recordingCheck || _recordingTransitioning) return;

    // set recoding to true
    _recordingCheck = true;

    try {
      if (_disposed) return;

      if (_recorder.isRecording) {
        WakelockPlus.disable();
        _timer?.cancel();

        await _recorder.pauseRecorder();

        // Nothing is being captured while paused, so the service — and the
        // microphone notification announcing it — should not be up either.
        await _stopForegroundService();

        _emit(status: AudioRecordingStatus.paused);
        return;
      }

      if (_recorder.isPaused) {
        WakelockPlus.enable();

        // Started here rather than only on a fresh take: this tap is a
        // foreground moment, and resuming without it leaves the rest of the
        // recording unprotected against a background switch.
        await _startForegroundService();

        // Resuming out of an audio issue: the session may have been
        // deactivated and the route replaced under us, so both are reclaimed
        // before the encoder writes again. A device removal has no
        // interruption-end event to run [_handleInterruptionEnd], so this is
        // also the only place that can clear the banner — without it the
        // header stays on "Recording Interrupted" for the rest of the take.
        if (_state.value.isInterrupted) {
          await _activateAudioSession();
          await _captureInputDevices();
        }

        await _recorder.resumeRecorder();

        _emit(
          status: AudioRecordingStatus.recording,
          isInterrupted: false,
        );

        _startTimer();
        return;
      }

      _recordingTransitioning = true;

      //start fresh
      final path = await _filePath();
      WakelockPlus.enable();

      // Activation is what registers the Android audio-focus listener backing
      // `interruptionEventStream` — audio_session only attaches it inside
      // setActive(true), so without this the interruption handling above is
      // iOS-only. iOS gets its notifications from the session singleton
      // regardless, so this is safe on both. Failure is reported and does not
      // abort the take: a degraded recording still beats none.
      await _activateAudioSession();
      await _captureInputDevices();

      // Before startRecorder(), so the mic is already protected by the time
      // anything is being written. Failure is not fatal here either: it means
      // the take is foreground-only, and handleAppBackgrounded() pauses
      // instead of letting Android hand the encoder silence.
      await _startForegroundService();

      await _recorder.startRecorder(toFile: path);

      _recordingStartedAt = DateTime.now();

      _emit(status: AudioRecordingStatus.recording);

      _startTimer();

      // Prevent an immediate stop after startRecorder().
      await Future<void>.delayed(
        const Duration(milliseconds: 400),
      );
    } catch (e, s) {
      debugPrint('record() failed: $e');

      CrashlyticsService().recordError(
        e,
        s,
        reason: 'record() failed',
      );

      // Enabled above, before startRecorder() — so a throw from the start or
      // resume path would otherwise hold the screen awake for the rest of the
      // app's life with nothing recording. Same for the service, whose
      // notification would otherwise claim a recording that never began.
      WakelockPlus.disable();
      await _stopForegroundService();

      _emit(status: AudioRecordingStatus.stopped);
    } finally {
      _recordingTransitioning = false;
      _recordingCheck = false;
    }
  }

  /// Ends the take, reporting whether the recorder actually stopped.
  ///
  /// The return value is what the [limit] timer gates [onLimitReached] on, and
  /// what a caller should gate a [save] on: a stop that never happened leaves
  /// no file to persist.
  Future<bool> stop() async {
    final startedAt = _recordingStartedAt;
    if (startedAt == null) {
      return false;
    }

    if (DateTime.now().difference(startedAt) < _minimumRecordingStartDelay) {
      return false;
    }

    // Cancelled before the call, not after: a throw below would otherwise
    // leave the limit branch of _startTimer() re-firing stop() every second.
    _timer?.cancel();
    _recordingStartedAt = null;

    // Released either way: no branch below leaves this service capturing, and
    // only save() used to disable it — so stopping and then closing the UI,
    // which is allowed once recording has ended, kept the screen awake for the
    // rest of the app's life.
    WakelockPlus.disable();
    await _stopForegroundService();

    try {
      _takePath = await _recorder.stopRecorder();

      _emit(status: AudioRecordingStatus.stopped);

      return true;
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'stopRecorder failed',
      );

      // Re-armed so the stop control keeps working. Leaving this null strands
      // the recorder: every later tap returns at the guard above, and
      // hasCompletedTake never turns true, so neither stop nor save is ever
      // reachable again and the take is lost.
      _recordingStartedAt = startedAt;

      // Not stopped — there is no file to save, so the UI must not offer the
      // save control. Paused is the honest "not capturing right now" state and
      // keeps stop on screen for a retry.
      _emit(status: AudioRecordingStatus.paused);

      return false;
    }
  }

  /// Throws away the take just captured, so a fresh [record] starts clean.
  ///
  /// The file is deleted rather than orphaned because the participant has
  /// explicitly rejected it. The path reference is cleared either way, so a
  /// later [save] cannot persist a path that no longer exists.
  Future<void> discardTake() async {
    _timer?.cancel();

    _emit(elapsed: Duration.zero);

    final path = _takePath;
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
  /// submission still reaches DynamoDB — so the file is checked before it is
  /// handed over, and an empty take resets itself and reports
  /// [RecordingSaveOutcome.emptyFile] instead.
  ///
  /// Writing the answer away and closing the UI stay with the caller: this
  /// class knows about audio, not about the diary it belongs to.
  Future<RecordingSaveResult> save() async {
    WakelockPlus.disable();
    try {
      _timer?.cancel();

      // Normally already down via stop(), but save() is also the confirm
      // control's handler and the timer-limit path, so it releases the service
      // itself rather than trusting the order it was reached in. A no-op once
      // the release has already happened. After the cancel above, so no tick
      // can land in the gap.
      await _stopForegroundService();

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

        _emit(elapsed: Duration.zero);

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
  /// This is the fallback for a device where [_startForegroundService] failed
  /// — permissions refused, an OEM restriction, a stop that did not take. In
  /// that state Android hands the recorder silence, so pausing is the honest
  /// outcome: nothing is lost and the take can be resumed.
  ///
  /// iOS is left recording. It declares the `audio` background mode, so
  /// capture genuinely continues there, and pausing would interrupt a take
  /// for a glance at a notification.
  Future<void> handleAppBackgrounded() async {
    if (!Platform.isAndroid ||
        _foregroundServiceActive ||
        !_recorder.isRecording) {
      return;
    }

    WakelockPlus.disable();
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

    // Outside the try, as in _pauseForAudioIssue(): the timer above is
    // already cancelled, so leaving this on recording would freeze the
    // elapsed count and kill the [limit] auto-stop.
    _emit(status: AudioRecordingStatus.paused);
  }

  /// Reclaims the audio session when the app comes back to the foreground.
  ///
  /// Only ever for a session this service was actually using. Reactivating
  /// unconditionally claims exclusive audio focus on every return to the
  /// foreground, so merely having the recording UI open and glancing at
  /// another app would stop the participant's music for a recording that never
  /// started.
  Future<void> handleAppResumed() async {
    if (!_recorder.isRecording && !_recorder.isPaused) return;

    await _activateAudioSession();
  }

  /// Releases the microphone, the audio session, the wakelock and the
  /// foreground service. The instance cannot record after this.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    _timer?.cancel();
    unawaited(_interruptionSubscription?.cancel());
    unawaited(_devicesChangedSubscription?.cancel());
    unawaited(_becomingNoisySubscription?.cancel());
    _interruptionSubscription = null;
    _devicesChangedSubscription = null;
    _becomingNoisySubscription = null;

    // The recording UI can be torn down without either control being tapped —
    // a system back gesture, a route pop — so the lock and the audio focus are
    // released here rather than only in stop()/save().
    WakelockPlus.disable();
    await _stopForegroundService();
    await _deactivateAudioSession();
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
  }) {
    if (_disposed) return;

    _state.value = _state.value.copyWith(
      status: status,
      elapsed: elapsed,
      isInterrupted: isInterrupted,
    );
  }

  /// Ticks the elapsed count, and stops the take once [limit] is reached.
  void _startTimer() {
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
  /// locked; stopping first flushes what was captured to disk. The take is not
  /// saved — nothing here has the participant's consent to persist it — so the
  /// file is left on disk unreferenced. Reclaiming those orphans is a separate
  /// job; no cleanup pass exists yet.
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

  /// Configures the recording foreground service.
  ///
  /// Every option that would let the service outlive a take is off:
  /// [ForegroundTaskEventAction.nothing] because there is no task isolate to
  /// tick, and `autoRunOnBoot` / `autoRunOnMyPackageReplaced` /
  /// `allowAutoRestart` because a mic notification resurrected after a reboot,
  /// an update, or a process kill would sit there with no recorder behind it.
  /// `allowWakeLock` stays on: that is the CPU lock that keeps the encoder
  /// running while the screen is off, and is not the screen lock WakelockPlus
  /// holds.
  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'diary_recording',
        channelName: 'Diary recording',
        channelDescription:
            'Shown while a diary answer is being recorded, so recording '
            'continues if you leave the app.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      // iOS keeps capturing on the `audio` background mode alone, so it never
      // starts this service and has no notification to show.
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
        allowAutoRestart: false,
      ),
    );
  }

  /// Starts the microphone foreground service, reporting whether it is up.
  ///
  /// Android revokes the mic from a backgrounded app with no
  /// microphone-typed foreground service, while flutter_sound keeps writing
  /// regardless — so without this a take captures silence for the time spent
  /// away, and nothing downstream can tell.
  ///
  /// Called only from the tap that begins or resumes a take. Android 12+
  /// refuses to start a foreground service from the background, so starting
  /// it from [handleAppBackgrounded] would already be too late.
  ///
  /// `false` means this take is foreground-only, which is what
  /// [handleAppBackgrounded] falls back on.
  Future<bool> _startForegroundService() async {
    if (!Platform.isAndroid) return false;
    if (_foregroundServiceActive) return true;

    try {
      // A service left running by a previous recording would make startService
      // throw ServiceAlreadyStartedException; adopt it instead.
      if (await FlutterForegroundTask.isRunningService) {
        _foregroundServiceActive = true;
        return true;
      }

      final result = await FlutterForegroundTask.startService(
        serviceId: _recordingServiceId,
        serviceTypes: const [ForegroundServiceTypes.microphone],
        notificationTitle: 'Recording your answer',
        notificationText: 'Tap to return to your diary.',
        // No callback on purpose: the recorder lives in the main isolate and
        // the service exists only to hold microphone access. Passing one
        // would spawn a second engine with nothing to run in it.
      );

      if (result is ServiceRequestFailure) {
        CrashlyticsService().recordError(
          result.error,
          StackTrace.current,
          reason: 'Recording foreground service failed to start',
        );
        return false;
      }

      _foregroundServiceActive = true;
      return true;
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Recording foreground service failed to start',
      );

      return false;
    }
  }

  /// Stops the service once capture ends.
  ///
  /// The flag is cleared before the call, not after: if the stop fails, the
  /// honest assumption is that background capture can no longer be relied on,
  /// so [handleAppBackgrounded] should go back to pausing. Pausing a take
  /// that would have survived costs the participant a tap; trusting a service
  /// that is not there costs them the recording.
  Future<void> _stopForegroundService() async {
    if (!_foregroundServiceActive) return;
    _foregroundServiceActive = false;

    try {
      await FlutterForegroundTask.stopService();
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Recording foreground service failed to stop',
      );
    }
  }

  /// Snapshots the inputs available as a recording starts, so a later removal
  /// can be matched against the route we actually began on.
  Future<void> _captureInputDevices() async {
    try {
      final session = await AudioSession.instance;
      final devices = await session.getDevices(includeOutputs: false);

      _inputDeviceIds
        ..clear()
        ..addAll(devices.where((d) => d.isInput).map((device) => device.id));
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Input device snapshot failed',
      );
    }
  }

  /// Pauses when an input the recording started on disappears.
  ///
  /// Asking whether *any* input still exists would never be false: the
  /// built-in mic is always reported by [AudioSession.getDevices] and is never
  /// removed, so that test can never fire. Matching a removal against the
  /// snapshot instead is what catches the case that matters — a Bluetooth
  /// headset or wired mic dropping out and silently rerouting a live
  /// recording. The built-in mic sits harmlessly in the snapshot: it is never
  /// removed, so it can never trigger this.
  Future<void> _handleAudioDevicesChanged(
    AudioDevicesChangedEvent event,
  ) async {
    if (_disposed || !_recorder.isRecording) {
      return;
    }

    // A mic attached mid-recording takes over the route, so it becomes what a
    // later removal is matched against.
    for (final device in event.devicesAdded) {
      if (device.isInput) _inputDeviceIds.add(device.id);
    }

    var lostActiveInput = false;
    for (final device in event.devicesRemoved) {
      // Not `any`: it short-circuits, which would leave the rest of a
      // multi-device removal still marked as present.
      if (device.isInput && _inputDeviceIds.remove(device.id)) {
        lostActiveInput = true;
      }
    }

    if (!lostActiveInput) return;

    await _pauseForAudioIssue();
  }

  //interruption handler
  Future<void> _handleAudioInterruption(
    AudioInterruptionEvent event,
  ) async {
    if (!event.begin) {
      await _handleInterruptionEnd();
      return;
    }

    await _pauseForAudioIssue();
  }

  Future<void> _handleInterruptionEnd() async {
    if (_disposed || !_state.value.isInterrupted) {
      return;
    }

    // Stay interrupted when the session could not be revived.
    if (!await _activateAudioSession()) return;

    _emit(isInterrupted: false);
  }

  //helper method for audioIssue
  Future<void> _pauseForAudioIssue() async {
    if (_disposed || !_recorder.isRecording) {
      return;
    }

    WakelockPlus.disable();
    // Timer cancelled before the first await: a tick landing in that window
    // could reach the limit branch, run stop() to completion, and then have
    // its stopped status overwritten by the paused below — hiding the save
    // control on a take that had in fact finished.
    _timer?.cancel();
    await _stopForegroundService();

    try {
      await _recorder.pauseRecorder();
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Failed to pause recorder for audio issue',
      );
    }

    // Published outside the try, so a failed pause still moves the UI. The
    // audio system has told us the route or the focus is gone, which means
    // whatever the encoder is still writing cannot be trusted — and the timer
    // above is already cancelled, so leaving this on recording would freeze
    // the elapsed count, kill the [limit] auto-stop, and show "Recording" to a
    // participant who is no longer being captured.
    _emit(
      status: AudioRecordingStatus.paused,
      isInterrupted: true,
    );
  }

  /// Applies the recording configuration and returns the shared session so
  /// callers can activate it when needed.
  Future<AudioSession> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      //Allows exclusive hard pause on other media players
      androidAudioFocusGainType:
          AndroidAudioFocusGainType.gainTransientExclusive,
      androidWillPauseWhenDucked: true,
    ));
    return session;
  }

  /// Configures and activates the audio session — both to claim it for a fresh
  /// recording and to restore it after an interruption or a return to the
  /// foreground. Reports failure by returning `false` rather than throwing: it
  /// is called unawaited from [handleAppResumed], where an escaping error
  /// would reach `PlatformDispatcher.onError` and be recorded as a *fatal*.
  Future<bool> _activateAudioSession() async {
    try {
      final session = await _configureAudioSession();
      await session.setActive(true);
      return true;
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Audio session activation failed',
      );

      return false;
    }
  }

  /// Hands the audio session back once this service is done capturing.
  ///
  /// [AndroidAudioFocusGainType.gainTransientExclusive] is a loan: the media
  /// app that paused for us only resumes when we abandon focus, which is what
  /// `setActive(false)` maps to. Without this the participant records one
  /// answer and their music stays dead for the rest of the process. iOS needs
  /// `notifyOthersOnDeactivation` for the same reason — it is what sends the
  /// other app its `shouldResume` hint — so it is passed here rather than in
  /// the configuration, where it would also apply to activation.
  ///
  /// Never called on a pause: releasing focus mid-recording would let the
  /// other app's audio back in to bleed into the mic on resume.
  Future<void> _deactivateAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(
        false,
        avAudioSessionSetActiveOptions:
            AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
      );
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Audio session deactivation failed',
      );
    }
  }

  /// Where the next take is written: `<documents>/audios/audio_prompt_N_<date>.aac`.
  Future<String> _filePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = await Directory(p.join(directory.path, 'audios'))
        .create(recursive: true);
    final now = DateTime.now();
    final fileName = 'audio_prompt_${promptId + 1}_${formatDate(now)}.aac';
    return p.join(dir.path, fileName);
  }

  //missing file helper function
  Future<bool> _hasValidAudioFile(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      return false;
    }

    var length = await file.length();

    if (length > 0) {
      return true;
    }

    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );

    if (!await file.exists()) {
      return false;
    }

    length = await file.length();

    return length > 0;
  }
}
