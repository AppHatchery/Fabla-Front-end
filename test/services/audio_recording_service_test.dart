import 'dart:async';
import 'dart:io';

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/services/audio_recording_service.dart';
import 'package:audio_diaries_flutter/services/recording_audio_session.dart';
import 'package:audio_diaries_flutter/services/recording_foreground_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

// Covers `AudioRecordingService` — the recorder, audio session, foreground
// service, wakelock, timer and take-on-disk that used to live inside
// `_BottomRecordingModalState`.
//
// ------------------------------------------------------------------
// How far a test can drive the real service
// ------------------------------------------------------------------
// The service is a plain class, so it can be built and driven directly. Two
// dependencies are stubbed at the channel so it runs in the test VM:
// wakelock_plus, and path_provider (which also doubles as the probe for
// whether a `record()` got past the guard).
//
// `FlutterSoundRecorder` can be driven too. `startRecorder` and `stopRecorder`
// settle on callbacks the native side posts back, and those are public methods,
// so a stubbed channel can post them itself and a whole take runs against a
// real file on disk.
//
// That covers the timing cases as well — an encoder still flushing, a file
// deleted inside the grace period — against the real service rather than a
// copy of its private methods.
// ------------------------------------------------------------------

/// wakelock_plus talks pigeon, not a plain method channel, so it is stubbed by
/// name. A wakelock_plus upgrade that renames this fails loudly with
/// `PlatformException(channel-error, ...)` rather than silently skipping.
const _wakelockToggleChannel =
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

const _recorderChannel = MethodChannel('xyz.canardoux.flutter_sound_recorder');

const _audioSessionChannel = MethodChannel('com.ryanheise.audio_session');

/// `RecorderState.isStopped`, `.isPaused` and `.isRecording`. The enum lives
/// in flutter_sound_platform_interface, which is not a direct dependency.
const _stateStopped = 0;
const _statePaused = 1;
const _stateRecording = 2;

/// Stands in for the Android microphone service, which needs a real Android to
/// do anything and reports only a bool to the outside.
///
/// Injected rather than stubbed at the channel so the *order* it is started
/// and stopped in is observable — that ordering is the whole point of the
/// service, and it was invisible from outside the class before.
class _FakeForegroundService implements RecordingForegroundService {
  _FakeForegroundService({required this.calls});

  /// Shared with the recorder's channel stub, so one list shows the order
  /// between "the microphone is protected" and "the encoder is writing".
  final List<String> calls;

  bool _active = false;

  @override
  bool get isActive => _active;

  @override
  void configure() => calls.add('service.configure');

  @override
  Future<bool> start() async {
    calls.add('service.start');
    _active = true;
    return true;
  }

  @override
  Future<void> stop() async {
    calls.add('service.stop');
    _active = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioRecordingState', () {
    test('starts stopped, at zero, and uninterrupted', () {
      const state = AudioRecordingState();

      expect(state.status, AudioRecordingStatus.stopped);
      expect(state.elapsed, Duration.zero);
      expect(state.isInterrupted, isFalse);
      expect(state.hasTake, isFalse);
      expect(state.takeWasEmpty, isFalse);
      expect(state.isRecording, isFalse);
      expect(state.isPaused, isFalse);
    });

    // Distinct from `!hasTake`, which is also true before anything has been
    // recorded. Only a take that ran and came back with nothing sets this, and
    // it is the one outcome the participant cannot read off the controls.
    test('an empty take is distinguishable from nothing recorded yet', () {
      const nothingYet = AudioRecordingState();
      const cameBackEmpty = AudioRecordingState(takeWasEmpty: true);

      expect(nothingYet.hasTake, cameBackEmpty.hasTake);
      expect(nothingYet.takeWasEmpty, isFalse);
      expect(cameBackEmpty.takeWasEmpty, isTrue);
      expect(cameBackEmpty.hasCompletedTake, isFalse,
          reason: 'there is nothing to save');
    });

    // The save and redo controls hang off this, so a take that captured
    // nothing must not look finished.
    test('only reports a completed take once a stop has captured a file', () {
      const nothingRecorded = AudioRecordingState();
      const recording = AudioRecordingState(
        status: AudioRecordingStatus.recording,
        elapsed: Duration(seconds: 12),
        hasTake: true,
      );
      const paused = AudioRecordingState(
        status: AudioRecordingStatus.paused,
        elapsed: Duration(seconds: 12),
        hasTake: true,
      );
      const stopped = AudioRecordingState(
        elapsed: Duration(seconds: 12),
        hasTake: true,
      );

      expect(nothingRecorded.hasCompletedTake, isFalse);
      expect(recording.hasCompletedTake, isFalse);
      expect(paused.hasCompletedTake, isFalse);
      expect(stopped.hasCompletedTake, isTrue);
    });

    // Stopping is allowed from _minimumRecordingStartDelay, which lands before
    // the elapsed counter's first tick. Gating completion on the clock left a
    // take stopped in that window with a file on disk, no save control, and no
    // way to reach it.
    test('a take shorter than the first tick is still completed', () {
      const stoppedSubSecond = AudioRecordingState(
        elapsed: Duration.zero,
        hasTake: true,
      );

      expect(stoppedSubSecond.hasCompletedTake, isTrue);
    });

    test('a stop that captured no file is not a completed take', () {
      const stoppedEmptyHanded = AudioRecordingState(
        elapsed: Duration(seconds: 12),
      );

      expect(stoppedEmptyHanded.hasCompletedTake, isFalse);
    });

    test('copyWith replaces only what it is given', () {
      const state = AudioRecordingState(
        status: AudioRecordingStatus.recording,
        elapsed: Duration(seconds: 3),
        isInterrupted: true,
      );

      final paused = state.copyWith(status: AudioRecordingStatus.paused);

      expect(paused.status, AudioRecordingStatus.paused);
      expect(paused.elapsed, const Duration(seconds: 3));
      expect(paused.isInterrupted, isTrue);
    });

    test('copyWith can clear the interruption flag', () {
      const interrupted = AudioRecordingState(
        status: AudioRecordingStatus.paused,
        isInterrupted: true,
      );

      expect(interrupted.copyWith(isInterrupted: false).isInterrupted, isFalse);
    });

    // Value equality is what lets the ValueNotifier behind
    // AudioRecordingService.state drop a publish that changes nothing, so a
    // handler re-asserting the current state does not rebuild the modal.
    test('equal states compare equal so a no-op publish can be dropped', () {
      const first = AudioRecordingState(
        status: AudioRecordingStatus.recording,
        elapsed: Duration(seconds: 5),
      );
      const second = AudioRecordingState(
        status: AudioRecordingStatus.recording,
        elapsed: Duration(seconds: 5),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('a difference in any field compares unequal', () {
      const base = AudioRecordingState(
        status: AudioRecordingStatus.recording,
        elapsed: Duration(seconds: 5),
      );

      expect(base, isNot(base.copyWith(status: AudioRecordingStatus.paused)));
      expect(base, isNot(base.copyWith(elapsed: const Duration(seconds: 6))));
      expect(base, isNot(base.copyWith(isInterrupted: true)));
      expect(base, isNot(base.copyWith(hasTake: true)));
      expect(base, isNot(base.copyWith(takeWasEmpty: true)));
    });
  });

  group('RecordingSaveResult', () {
    // The caller does `basePath(result.path!)`, so the path has to be there on
    // a save and absent on everything else.
    test('carries a path only when the take was saved', () {
      const saved = RecordingSaveResult(
        RecordingSaveOutcome.saved,
        '/documents/audios/audio_prompt_1_2026-09-02.m4a',
      );

      expect(saved.outcome, RecordingSaveOutcome.saved);
      expect(saved.path, isNotNull);

      for (final outcome in [
        RecordingSaveOutcome.nothingRecorded,
        RecordingSaveOutcome.emptyFile,
        RecordingSaveOutcome.failed,
      ]) {
        expect(RecordingSaveResult(outcome).path, isNull);
      }
    });
  });

  // -------------------------------------------------------------------
  // The recorder single-flight guard — driven against the real service
  // -------------------------------------------------------------------
  //
  // `record()` and `stop()` back two controls sitting side by side and drive
  // the same recorder, so a tap on one while the other is awaiting would put
  // two calls on it at once. `_recorderBusy` is held across all four
  // transitions — start, pause, resume, stop — and first in wins.
  //
  // The production signature this defends against is
  // `PlatformException(Recorder, _RecorderRunningException, ...)`, thrown by
  // the native side when `startRecorder` lands on a running recorder
  // (Crashlytics issue 5330796079a5951a2da4212179a46f7b).
  //
  // The probe: `record()` reaches `_filePath()` before it touches the recorder,
  // so a parked path_provider stub holds a take mid-flight, and the call count
  // says how many takes got past the guard.
  // -------------------------------------------------------------------
  group('recorder guard', () {
    late int documentsDirCalls;
    Completer<void>? gate;

    setUp(() {
      documentsDirCalls = 0;
      gate = null;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        _wakelockToggleChannel,
        (_) async =>
            const StandardMessageCodec().encodeMessage(<Object?>[null]),
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_pathProviderChannel, (call) async {
        if (call.method != 'getApplicationDocumentsDirectory') return null;

        documentsDirCalls++;
        if (gate != null) await gate!.future;

        // Fails the take deliberately. Letting it succeed would hand the
        // unopened FlutterSoundRecorder a startRecorder it cannot answer, and
        // the orphaned future it leaks out of `synchronized` fails the test
        // from outside the call under test.
        throw PlatformException(code: 'no-documents-directory');
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockMessageHandler(_wakelockToggleChannel, null)
        ..setMockMethodCallHandler(_pathProviderChannel, null);
    });

    test('a second record() while the first is in flight never starts a take',
        () async {
      final service = AudioRecordingService(promptId: 0);
      gate = Completer<void>();

      final inFlight = service.record();
      await Future<void>.delayed(Duration.zero);
      expect(documentsDirCalls, 1);

      await service.record();

      expect(documentsDirCalls, 1,
          reason: 'the guard must swallow the reentrant tap');

      gate!.complete();
      await inFlight;
    });

    test('a burst of taps mid-flight only lets one take through', () async {
      final service = AudioRecordingService(promptId: 0);
      gate = Completer<void>();

      final inFlight = service.record();
      await Future<void>.delayed(Duration.zero);

      for (var i = 0; i < 20; i++) {
        await service.record();
      }

      expect(documentsDirCalls, 1,
          reason: 'the guard is O(1) regardless of burst size');

      gate!.complete();
      await inFlight;
    });

    // The stop control sits next to the record control, and before the guard
    // covered both they could reach the recorder together.
    test('stop() while a record() is in flight is refused', () async {
      final service = AudioRecordingService(promptId: 0);
      gate = Completer<void>();

      final inFlight = service.record();
      await Future<void>.delayed(Duration.zero);

      expect(await service.stop(), isFalse);

      gate!.complete();
      await inFlight;
    });

    // The two kinds of caller are deliberately different: a tap that arrives
    // mid-transition is dropped, while the audio-system handlers queue behind
    // it via _acquireRecorderLock(). If stop() were ever switched to waiting
    // too, this returns after _lockWaitTimeout instead of immediately, and the
    // participant's tap appears to hang.
    test('a refused stop() gives up at once rather than queueing', () async {
      final service = AudioRecordingService(promptId: 0);
      gate = Completer<void>();

      final inFlight = service.record();
      await Future<void>.delayed(Duration.zero);

      final started = DateTime.now();
      final stopped = await service.stop();
      final waited = DateTime.now().difference(started);

      expect(stopped, isFalse);
      expect(
        waited,
        lessThan(const Duration(milliseconds: 200)),
        reason: 'taps are ignored, not queued',
      );

      gate!.complete();
      await inFlight;
    });

    // Teardown deactivates the session and closes the recorder. Doing that on
    // top of a live startRecorder() is what leaves a file truncated and the
    // native recorder locked, so dispose() waits the transition out instead of
    // racing it.
    test('dispose() waits for an in-flight transition before tearing down',
        () async {
      final service = AudioRecordingService(promptId: 0);
      gate = Completer<void>();

      final inFlight = service.record();
      await Future<void>.delayed(Duration.zero);

      var tornDown = false;
      final disposal = service.dispose().then((_) => tornDown = true);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(tornDown, isFalse,
          reason: 'teardown must not start mid-transition');

      gate!.complete();
      await inFlight;
      await disposal;

      expect(tornDown, isTrue);
    });

    // The guard releases in `finally`, so a take that blew up is retryable.
    // Leaving it held would strand the modal: every later tap on record would
    // return at the guard and nothing would ever be captured again.
    test('a failed record() releases the guard so the next tap gets through',
        () async {
      final service = AudioRecordingService(promptId: 0);

      await service.record();

      expect(documentsDirCalls, 1);
      expect(service.state.value.status, AudioRecordingStatus.stopped,
          reason: 'a take that never began must not look like it is recording');

      await service.record();

      expect(documentsDirCalls, 2, reason: 'the retry must reach the recorder');
    });

    test('record() after dispose does nothing', () async {
      final service = AudioRecordingService(promptId: 0);
      await service.dispose();

      await service.record();

      expect(documentsDirCalls, 0);
    });

    test('stop() after dispose reports that nothing stopped', () async {
      final service = AudioRecordingService(promptId: 0);
      await service.dispose();

      expect(await service.stop(), isFalse);
    });

    // `stop()`'s return value is what the limit timer gates `onLimitReached` on
    // and what the modal gates a save on, so a stop with no take behind it has
    // to report false rather than let an empty answer through.
    test('stop() with no take started reports that nothing stopped', () async {
      final service = AudioRecordingService(promptId: 0);

      expect(await service.stop(), isFalse);
    });
  });

  // -------------------------------------------------------------------
  // save() — the reachable half, driven against the real service
  // -------------------------------------------------------------------
  group('save()', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
        _wakelockToggleChannel,
        (_) async =>
            const StandardMessageCodec().encodeMessage(<Object?>[null]),
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(_wakelockToggleChannel, null);
    });

    // save() is also the handler for a take that ran out its limit, so it is
    // reached with nothing captured and must say so rather than throw.
    test('reports nothingRecorded when no take was captured', () async {
      final service = AudioRecordingService(promptId: 0);

      final result = await service.save();

      expect(result.outcome, RecordingSaveOutcome.nothingRecorded);
      expect(result.path, isNull);
      expect(service.state.value.status, AudioRecordingStatus.stopped);
    });
  });

  group('discardTake()', () {
    test('zeroes the elapsed count so the next take starts from 00:00',
        () async {
      final service = AudioRecordingService(promptId: 0);

      await service.discardTake();

      expect(service.state.value.elapsed, Duration.zero);
    });
  });

  // -------------------------------------------------------------------
  // A whole take, driven against the real service and a real file
  // -------------------------------------------------------------------
  //
  // The stubbed method channel plays the native side: it posts the completion
  // callbacks flutter_sound is waiting on, and writes the file the encoder
  // would have written. Two knobs cover the failure modes that matter —
  // whether the encoder produced anything, and what `stopRecorder` claims the
  // path is.
  // -------------------------------------------------------------------
  group('a take from record() to save()', () {
    late Directory documents;
    late AudioRecordingService service;

    /// The path `startRecorder` was asked to write.
    String? startedPath;

    /// Whether the stubbed encoder writes anything. flutter_sound creates the
    /// file lazily on the first audio write, so `false` reproduces the take
    /// that leaves a valid-looking path pointing at nothing.
    late bool encoderWritesFile;

    /// Whether the encoder opens the file but never writes to it — the take
    /// that leaves a real, zero-byte `.m4a` behind rather than no file at all.
    late bool encoderLeavesEmptyFile;

    /// What the stubbed native side hands back from `stopRecorder`. Not always
    /// a path in production — see `_locateTake`.
    late String? Function(String requestedPath) reportedStopPath;

    /// Runs when the stub receives `stopRecorder`, once, then clears itself.
    ///
    /// The last moment a test can see before `_locateTake` starts its grace
    /// period, so anything that must happen inside that window is scheduled
    /// from here and flutter_sound's round trip is not part of the margin.
    ///
    /// One shot because `tearDown` disposes the service, which stops the
    /// recorder again — left armed it would fire into a finished test.
    late void Function()? onStopRecorderCall;

    /// Whether the native side reports the stop as having succeeded.
    ///
    /// `false` is how flutter_sound signals a failed stop: it completes the
    /// completer with the *string* `'stopRecorder failed'`, which its own
    /// `on Exception` guard does not catch, so it lands in `stop()`'s catch.
    /// The recorder is left in `isStopped` either way.
    late bool stopSucceeds;

    /// Whether `startRecorder` refuses. A recorder wedged by an earlier failed
    /// stop is the realistic way a following take never begins.
    late bool startRecorderFails;

    /// Every platform call `initialize()` makes, in order, across both the
    /// recorder and the audio session. Ordering between the two is load
    /// bearing — see the setSubscriptionDuration test below.
    late List<String> platformCalls;

    /// The microphone service, injected so its calls land in [platformCalls]
    /// alongside the recorder's and the order between them can be read off.
    late _FakeForegroundService foregroundService;

    /// What `RecordingAudioSession` would call when the route or the focus
    /// goes. Captured through the injected factory, because the handler behind
    /// it is private and there is no live audio system here to trigger it.
    late Future<void> Function() captureCompromised;

    setUp(() {
      documents = Directory.systemTemp.createTempSync('take');
      startedPath = null;
      encoderWritesFile = true;
      encoderLeavesEmptyFile = false;
      reportedStopPath = (requested) => requested;
      onStopRecorderCall = null;
      stopSucceeds = true;
      startRecorderFails = false;
      platformCalls = [];
      foregroundService = _FakeForegroundService(calls: platformCalls);

      service = AudioRecordingService(
        promptId: 0,
        foregroundService: foregroundService,
        // Kept, rather than replaced: the real session is harmless against the
        // stubbed channel, and the factory is here to catch the handler it is
        // built with, which is the only way in to the audio-issue pause.
        audioSessionFactory: ({
          required onCaptureCompromised,
        }) {
          captureCompromised = onCaptureCompromised;
          return RecordingAudioSession(
            onCaptureCompromised: onCaptureCompromised,
          );
        },
      );

      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      messenger.setMockMessageHandler(
        _wakelockToggleChannel,
        (_) async =>
            const StandardMessageCodec().encodeMessage(<Object?>[null]),
      );

      messenger.setMockMethodCallHandler(_pathProviderChannel, (call) async {
        if (call.method != 'getApplicationDocumentsDirectory') return null;
        return documents.path;
      });

      messenger.setMockMethodCallHandler(_audioSessionChannel, (call) async {
        platformCalls.add('session.${call.method}');
        return null;
      });

      messenger.setMockMethodCallHandler(_recorderChannel, (call) async {
        platformCalls.add('recorder.${call.method}');

        switch (call.method) {
          case 'isEncoderSupported':
            return true;

          // Each of these settles a completer flutter_sound created just
          // before it reached the channel. Deferred by a microtask so the
          // platform call it belongs to has returned first.
          case 'openRecorder':
            scheduleMicrotask(
              () => service.recorder.openRecorderCompleted(_stateStopped, true),
            );
            return null;

          case 'startRecorder':
            if (startRecorderFails) {
              // No file was opened, so the native side has no url to report
              // for it either. Left set, the stub would hand the *next* stop
              // the previous take's path and stand in for the very leak these
              // tests are checking for.
              startedPath = null;
              throw PlatformException(code: 'startRecorder refused');
            }

            final path = (call.arguments as Map)['path'] as String;
            startedPath = path;
            if (encoderWritesFile) {
              File(path).writeAsBytesSync([1, 2, 3, 4]);
            } else if (encoderLeavesEmptyFile) {
              File(path).createSync();
            }

            scheduleMicrotask(
              () => service.recorder
                  .startRecorderCompleted(_stateRecording, true),
            );
            return null;

          // Without these two, flutter_sound waits forever on a completer
          // nothing settles, and any test that pauses hangs rather than fails.
          case 'pauseRecorder':
            scheduleMicrotask(
              () => service.recorder.pauseRecorderCompleted(_statePaused, true),
            );
            return null;

          case 'resumeRecorder':
            scheduleMicrotask(
              () => service.recorder
                  .resumeRecorderCompleted(_stateRecording, true),
            );
            return null;

          case 'stopRecorder':
            final onStop = onStopRecorderCall;
            onStopRecorderCall = null;
            onStop?.call();

            final started = startedPath;
            final reported = started == null ? null : reportedStopPath(started);
            scheduleMicrotask(
              () => service.recorder.stopRecorderCompleted(
                _stateStopped,
                stopSucceeds,
                reported,
              ),
            );
            return null;
        }

        return null;
      });
    });

    tearDown(() async {
      // Before the handlers go: dispose() stops and closes the recorder, so it
      // needs the stubbed native side still answering. A test that leaves a
      // take running would otherwise leak its one-second timer into every test
      // that follows, ticking against channels that are no longer there.
      await service.dispose();

      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      messenger
        ..setMockMessageHandler(_wakelockToggleChannel, null)
        ..setMockMethodCallHandler(_pathProviderChannel, null)
        ..setMockMethodCallHandler(_audioSessionChannel, null)
        ..setMockMethodCallHandler(_recorderChannel, null);

      if (documents.existsSync()) documents.deleteSync(recursive: true);
    });

    /// Opens the recorder and captures a take, leaving it running.
    Future<void> startTake() async {
      await service.initialize();
      await service.record();

      expect(service.state.value.isRecording, isTrue,
          reason: 'the take must be running before the test acts on it');
    }

    // flutter_sound's default subscription duration is zero, which it
    // documents as "no callbacks" — so if setting it sat behind the audio
    // session in the same try, one session failure would cost the waveform
    // every level for the whole session, surfacing only as an unrelated audio
    // error. Ordering is the fix, so ordering is what this pins.
    test('the progress rate is set before anything can fail on the session',
        () async {
      await service.initialize();

      final rateSet = platformCalls.indexOf('recorder.setSubscriptionDuration');
      final sessionConfigured =
          platformCalls.indexOf('session.setConfiguration');

      expect(rateSet, isNonNegative, reason: 'the rate must be set at all');
      expect(sessionConfigured, isNonNegative,
          reason: 'the session must be configured at all');
      expect(rateSet, lessThan(sessionConfigured));
    });

    /// Index of [call] in the shared log, asserted to be present first so a
    /// missing call fails as itself rather than as a confusing -1 ordering.
    int callIndex(String call) {
      final index = platformCalls.indexOf(call);
      expect(index, isNonNegative, reason: '$call never happened');
      return index;
    }

    // ----------------------------------------------------------------
    // Ordering around the microphone service
    // ----------------------------------------------------------------
    //
    // Android revokes the microphone from a backgrounded app with no
    // microphone-typed service, while the encoder keeps writing regardless. So
    // the service has to be up before anything is captured and may only go
    // down once nothing is. Both halves are pure ordering, invisible from the
    // outside until the service could be injected.
    // ----------------------------------------------------------------

    test('the microphone is protected before the encoder writes', () async {
      await startTake();

      expect(callIndex('service.start'),
          lessThan(callIndex('recorder.startRecorder')));
    });

    test('a pause hands the microphone back only once the encoder has stopped',
        () async {
      await startTake();
      platformCalls.clear();

      await service.record();

      expect(service.state.value.isPaused, isTrue);
      expect(callIndex('recorder.pauseRecorder'),
          lessThan(callIndex('service.stop')),
          reason: 'dropping it first leaves a window with no protection');
    });

    // The same sequence, reached from the audio system rather than from a tap.
    // This path used to stop the service *before* pausing — the opposite order
    // — which is the divergence that came of writing the steps out three
    // times. Both go through one method now, so this pins that they agree.
    test('an audio issue pauses in the same order as the participant does',
        () async {
      await startTake();
      platformCalls.clear();

      await captureCompromised();

      expect(service.state.value.isPaused, isTrue);
      expect(service.state.value.isInterrupted, isTrue,
          reason: 'and unlike a tap, it says why');
      expect(callIndex('recorder.pauseRecorder'),
          lessThan(callIndex('service.stop')));
    });

    // Reclaiming the session belongs to the resume, and only an interrupted
    // take needs it. It used to happen the moment the audio system said the
    // interruption was over, which left this guard dead: the session was taken
    // back — and the route re-snapshotted — against whatever was plugged in
    // when Siri finished rather than when capture actually started again.
    test('resuming an interrupted take reclaims the session before capturing',
        () async {
      await startTake();
      await captureCompromised();
      platformCalls.clear();

      await service.record();

      expect(service.state.value.isRecording, isTrue);
      expect(service.state.value.isInterrupted, isFalse,
          reason: 'the take is capturing again, so there is nothing to resume');
      expect(callIndex('session.setConfiguration'),
          lessThan(callIndex('recorder.resumeRecorder')));
    });

    // The other half of that guard. An ordinary pause never lost the session,
    // and taking it again claims exclusive audio focus — which would stop the
    // participant's music for a take that never gave it up.
    test('resuming an ordinary pause leaves the session alone', () async {
      await startTake();
      await service.record();

      expect(service.state.value.isPaused, isTrue);
      expect(service.state.value.isInterrupted, isFalse);
      platformCalls.clear();

      await service.record();

      expect(service.state.value.isRecording, isTrue);
      expect(platformCalls, isNot(contains('session.setConfiguration')));
    });

    // Resuming used to be the only way out of the banner, so a participant who
    // answered an interruption by stopping kept it. The sheet then shows the
    // notice instead of the question, pointing at a resume button that a
    // stopped take does not have.
    test('stopping an interrupted take takes the banner down', () async {
      await startTake();
      await captureCompromised();

      expect(service.state.value.isInterrupted, isTrue);

      expect(await service.stop(), isTrue);

      expect(service.state.value.isInterrupted, isFalse,
          reason: 'nothing is capturing, so there is nothing to resume');
      expect(service.state.value.hasCompletedTake, isTrue);
    });

    // The same flag outliving the stop reached the *next* take: a healthy
    // recording ran under "Recording Interrupted", with the question hidden
    // behind it for the whole take.
    test('a fresh take does not inherit the last one\'s interruption',
        () async {
      await startTake();
      await captureCompromised();
      await service.stop();
      await service.discardTake();

      await service.record();

      expect(service.state.value.isRecording, isTrue);
      expect(service.state.value.isInterrupted, isFalse,
          reason: 'this take has not been interrupted by anything');
    });

    // An empty take and an interruption are different things to tell the
    // participant, and the sheet checks the interruption first — so a leftover
    // flag would explain a take that captured nothing as one to resume.
    test('a take that came back empty is not reported as interrupted',
        () async {
      encoderWritesFile = false;
      encoderLeavesEmptyFile = true;

      await startTake();
      await captureCompromised();

      expect(await service.stop(), isFalse);

      expect(service.state.value.takeWasEmpty, isTrue);
      expect(service.state.value.isInterrupted, isFalse,
          reason: 'the empty-take notice must not be masked');
    });

    // dispose() cancels the elapsed timer once, before waiting for an in-flight
    // move — so a start finishing inside that wait used to install a fresh one
    // with nothing left to cancel it. The leak publishes nothing, so the timer
    // is counted through the zone that created it.
    test('a dispose racing a start leaves no timer ticking', () async {
      await service.initialize();

      final elapsedTimers = <Timer>[];

      await runZoned(
        () async {
          // Neither awaited before the other: dispose() has to land while
          // _startTake() is still inside its awaits, which is what closing the
          // sheet on a back gesture does.
          final inFlight = service.record();
          final disposal = service.dispose();

          await inFlight;
          await disposal;
        },
        zoneSpecification: ZoneSpecification(
          createPeriodicTimer: (self, parent, zone, period, callback) {
            final timer = parent.createPeriodicTimer(zone, period, callback);
            if (period == const Duration(seconds: 1)) elapsedTimers.add(timer);
            return timer;
          },
        ),
      );

      expect(platformCalls, contains('recorder.startRecorder'),
          reason: 'the take has to get far enough to reach the timer at all');
      expect(elapsedTimers.where((timer) => timer.isActive), isEmpty,
          reason: 'the elapsed timer must not outlive the service');
    });

    // isActive is the answer to "can this take survive a background switch",
    // which is what handleAppBackgrounded() reads. A take paused for any
    // reason has handed the microphone back, so it must not still claim yes.
    //
    // Asserted on the calls rather than on the fake's own flag: the fake sets
    // that flag itself, so checking it after a start would pass no matter what
    // the service did.
    test('the service does not outlive the capture it was protecting',
        () async {
      await startTake();
      await service.record();

      expect(
        platformCalls.where((call) => call.startsWith('service.')),
        containsAllInOrder(['service.start', 'service.stop']),
        reason: 'started for the take, handed back when it paused',
      );
      expect(foregroundService.isActive, isFalse);
    });

    test('a take the encoder wrote is offered for saving, and saves', () async {
      await startTake();

      expect(await service.stop(), isTrue);
      expect(service.state.value.hasCompletedTake, isTrue);

      final result = await service.save();

      expect(result.outcome, RecordingSaveOutcome.saved);
      expect(result.path, startedPath);
      expect(File(result.path!).existsSync(), isTrue);
    });

    // flutter_sound returns the literal string 'Recorder is not open' rather
    // than a path when the recorder is not fully initialized, and an empty
    // string when the native side reports no url. Neither must lose a take
    // that is sitting on disk under the path the service asked for.
    test('a stop that reports a non-path still finds the take', () async {
      reportedStopPath = (_) => 'Recorder is not open';

      await startTake();

      expect(await service.stop(), isTrue);
      expect(service.state.value.hasCompletedTake, isTrue);

      final result = await service.save();

      expect(result.outcome, RecordingSaveOutcome.saved);
      expect(result.path, startedPath,
          reason: 'the requested path wins over what stopRecorder claimed');
    });

    // hasTake is what puts the save control on screen. Offering it for a take
    // with no file behind it means the participant confirms a finished-looking
    // recording and nothing happens.
    test('a take the encoder never wrote is not offered for saving', () async {
      encoderWritesFile = false;

      await startTake();

      expect(await service.stop(), isFalse);
      expect(service.state.value.status, AudioRecordingStatus.stopped,
          reason: 'the recorder did stop, so paused would be a lie');
      expect(service.state.value.hasTake, isFalse);
      expect(service.state.value.hasCompletedTake, isFalse);
    });

    // The sheet resets to 00:00 on this path, which on its own reads as a tap
    // that never registered. Without something to render, the participant
    // records the same answer again and loses it the same way.
    test('a take that produced nothing says so, and a retake clears it',
        () async {
      encoderWritesFile = false;

      await startTake();
      await service.stop();

      expect(service.state.value.takeWasEmpty, isTrue);

      encoderWritesFile = true;
      await service.record();

      expect(service.state.value.takeWasEmpty, isFalse,
          reason: 'a fresh take is not carrying the last one’s failure');
    });

    // A failed stop leaves the recorder stopped but re-arms the start time so
    // the stop can be retried, which puts the next tap on a fresh take rather
    // than a resume. If that take never opens a file, the only path left over
    // is the one the *first* take wrote — real audio, with bytes in it, and
    // the first thing _locateTake looks for.
    test('a take that never began cannot be saved as the previous one',
        () async {
      await startTake();
      final firstTake = startedPath!;

      // Set only now: flutter_sound stops the recorder itself on the way into
      // startRecorder(), so failing every stop would fail the take above too.
      stopSucceeds = false;

      expect(await service.stop(), isFalse, reason: 'the stop failed');
      expect(File(firstTake).existsSync(), isTrue,
          reason: 'but the audio it captured is on disk');

      stopSucceeds = true;
      startRecorderFails = true;
      await service.record();

      expect(service.state.value.isRecording, isFalse,
          reason: 'the second take never started');

      expect(await service.stop(), isFalse,
          reason: 'there is no second take to finish');
      expect(service.state.value.hasCompletedTake, isFalse,
          reason: 'the first take must not be offered in its place');

      expect((await service.save()).path, isNot(firstTake),
          reason: 'and it is never handed back as the answer');
    });

    // The take is over and both path references are dropped, so nothing can
    // reclaim the file afterwards — discardTake() reads a null path and
    // returns. Left behind, one empty .m4a per failed take would accumulate
    // for the life of the install.
    test('a take that captured nothing leaves no file behind', () async {
      encoderWritesFile = false;
      encoderLeavesEmptyFile = true;

      await startTake();
      final take = File(startedPath!);
      expect(take.existsSync(), isTrue,
          reason: 'the encoder opened it, it just never wrote');

      expect(await service.stop(), isFalse);
      expect(service.state.value.takeWasEmpty, isTrue);

      expect(take.existsSync(), isFalse, reason: 'and the stop cleaned it up');
    });

    // The two paths differ when the stop reports a name other than the one the
    // recorder was asked for, which only happens when the requested file
    // failed its check — here, opened and never written to. Redo used to
    // delete the located take and drop the reference to the placeholder
    // without deleting it, leaving an empty .m4a nothing points at.
    test('discarding a take also deletes the placeholder it never wrote to',
        () async {
      encoderWritesFile = false;
      encoderLeavesEmptyFile = true;

      final elsewhere = File(p.join(documents.path, 'audios', 'elsewhere.m4a'));
      reportedStopPath = (_) => elsewhere.path;

      await startTake();

      final placeholder = File(startedPath!);
      expect(placeholder.existsSync(), isTrue,
          reason: 'the encoder opened it and wrote nothing');

      elsewhere.writeAsBytesSync([1, 2, 3, 4]);

      expect(await service.stop(), isTrue,
          reason: 'the reported path is where the audio actually landed');

      await service.discardTake();

      expect(elsewhere.existsSync(), isFalse, reason: 'the take itself');
      expect(placeholder.existsSync(), isFalse,
          reason: 'and the empty file left beside it');
    });

    // ----------------------------------------------------------------
    // The grace period _locateTake gives the encoder
    // ----------------------------------------------------------------
    //
    // `stopRecorder()` can return while the file is still being flushed, so a
    // take that looks empty on the first read is given one more chance before
    // it is written off. Both halves matter: a late landing has to be picked
    // up, and a file that goes away in the meantime must not be resurrected.
    //
    // These two are timing tests, and the margin is stated rather than guessed.
    // Each change is scheduled from the `stopRecorder` stub, the last point
    // before the grace begins, and lands a quarter of the way into a grace
    // period read off the service — so changing it moves these tests with it.
    // ----------------------------------------------------------------

    /// A quarter of the real grace: comfortably inside it, and far enough from
    /// both ends that a slow machine does not change the ordering.
    final insideTheGrace = AudioRecordingService.encoderFlushGrace ~/ 4;

    test('a take still being flushed is picked up when it lands', () async {
      encoderWritesFile = false;
      encoderLeavesEmptyFile = true;

      await startTake();

      final take = File(startedPath!);
      expect(take.lengthSync(), 0, reason: 'nothing written yet');

      onStopRecorderCall = () => Timer(
            insideTheGrace,
            () => take.writeAsBytesSync([1, 2, 3, 4]),
          );

      expect(await service.stop(), isTrue);
      expect(service.state.value.hasCompletedTake, isTrue);
      expect((await service.save()).path, startedPath);
    });

    test('a take deleted inside the grace is not resurrected', () async {
      encoderWritesFile = false;
      encoderLeavesEmptyFile = true;

      await startTake();

      final take = File(startedPath!);

      onStopRecorderCall = () => Timer(insideTheGrace, take.deleteSync);

      expect(await service.stop(), isFalse);
      expect(service.state.value.takeWasEmpty, isTrue,
          reason: 'the participant is told the take captured nothing');
      expect(take.existsSync(), isFalse);
    });

    test('discarding a take clears the empty-take notice', () async {
      encoderWritesFile = false;

      await startTake();
      await service.stop();
      expect(service.state.value.takeWasEmpty, isTrue);

      await service.discardTake();

      expect(service.state.value.takeWasEmpty, isFalse);
    });

    // save() reaches the same conclusion from the other side: the file was
    // there when the take ended and is gone now.
    test('a take that disappears before saving raises the same notice',
        () async {
      await startTake();
      await service.stop();
      expect(service.state.value.takeWasEmpty, isFalse);

      File(startedPath!).deleteSync();
      await service.save();

      expect(service.state.value.takeWasEmpty, isTrue);
    });

    // The clock drives the progress bar and the [limit] auto-stop, so a
    // replacement take inheriting the failed one's count would be cut short by
    // however long that one ran.
    test('a take that produced nothing leaves the clock at zero', () async {
      encoderWritesFile = false;

      await startTake();

      // Past the first tick of the one-second elapsed counter.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(service.state.value.elapsed, greaterThan(Duration.zero));

      await service.stop();

      expect(service.state.value.elapsed, Duration.zero);
    });

    test('discarding a take deletes it and takes the save control away',
        () async {
      await startTake();
      await service.stop();

      final take = File(startedPath!);
      expect(take.existsSync(), isTrue);

      await service.discardTake();

      expect(take.existsSync(), isFalse);
      expect(service.state.value.hasTake, isFalse);
      expect(service.state.value.elapsed, Duration.zero);
    });

    // The gate in stop() has already passed by this point, so reaching it in
    // save() means the file went away in between.
    test('a take that disappears between stopping and saving reports empty',
        () async {
      await startTake();
      await service.stop();

      File(startedPath!).deleteSync();

      final result = await service.save();

      expect(result.outcome, RecordingSaveOutcome.emptyFile);
      expect(result.path, isNull);
      expect(service.state.value.hasTake, isFalse);
    });
  });
}
