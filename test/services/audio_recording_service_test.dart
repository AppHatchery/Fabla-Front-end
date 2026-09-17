import 'dart:async';
import 'dart:io';

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/services/audio_recording_service.dart';
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
// The service is a plain class now, so it can be constructed and driven
// directly. Two of its dependencies are stubbed at the channel to let it run in
// the test VM:
//
//   * wakelock_plus, because `save()` calls `WakelockPlus.disable()` outside
//     its try block, so an unstubbed pigeon channel throws straight out.
//   * path_provider, which `_filePath()` needs and which doubles as the probe
//     for whether a `record()` actually got past the guard.
//
// What cannot be driven is `FlutterSoundRecorder` itself: `startRecorder` and
// `stopRecorder` resolve on callbacks the native side posts back, so without a
// device the recorder never opens, `_takePath` is never set, and the branches
// behind it — a stop that captures a file, a save that validates one — are out
// of reach. Those are mirrored, clearly marked, at the bottom of this file.
//
// So the guard tests below are the real thing: they hold `record()` open on a
// parked path_provider call and count how many takes get through.
// ------------------------------------------------------------------

/// wakelock_plus talks pigeon, not a plain method channel, so it is stubbed by
/// name. A wakelock_plus upgrade that renames this fails loudly with
/// `PlatformException(channel-error, ...)` rather than silently skipping.
const _wakelockToggleChannel =
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioRecordingState', () {
    test('starts stopped, at zero, and uninterrupted', () {
      const state = AudioRecordingState();

      expect(state.status, AudioRecordingStatus.stopped);
      expect(state.elapsed, Duration.zero);
      expect(state.isInterrupted, isFalse);
      expect(state.hasTake, isFalse);
      expect(state.isRecording, isFalse);
      expect(state.isPaused, isFalse);
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
  // The file gate behind save() — mirrored
  // -------------------------------------------------------------------
  //
  // `_hasValidAudioFile` only ever runs on a `_takePath`, which only
  // `stopRecorder` sets, so it cannot be reached without a device. Mirrored
  // here because the rule it enforces is the data-loss fix: flutter_sound
  // creates the file lazily on the first audio write, so an inactive audio
  // session leaves a valid-looking path pointing at nothing. Persisting it
  // created a database row for audio that did not exist, which then failed
  // forever on playback and on S3 upload while the submission still committed
  // to DynamoDB.
  //
  // If you change `_hasValidAudioFile`, mirror the change here AND update these
  // tests — otherwise the spec drifts away from the impl.
  // -------------------------------------------------------------------
  group('save() file gate (mirrored)', () {
    late Directory audiosDir;

    setUp(() {
      // Mirrors <documents>/audios/, so basePath yields "audios/<file>".
      audiosDir = Directory(
        p.join(Directory.systemTemp.createTempSync('save_gate').path, 'audios'),
      )..createSync(recursive: true);
    });

    tearDown(() {
      final root = audiosDir.parent;
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    String pathFor(String name) => p.join(audiosDir.path, name);

    test('accepts a file that exists and has content', () async {
      final file = File(pathFor('clip.m4a'))..writeAsBytesSync([1, 2, 3, 4]);

      expect(await _hasValidAudioFile(file.path), isTrue);
    });

    test('rejects a file that was never written', () async {
      expect(await _hasValidAudioFile(pathFor('never_written.m4a')), isFalse);
    });

    test('rejects a zero byte file', () async {
      final file = File(pathFor('empty.m4a'))..createSync();

      expect(file.lengthSync(), 0);
      expect(await _hasValidAudioFile(file.path), isFalse);
    });

    // The encoder can still be flushing when stopRecorder returns, so a file
    // that is empty on the first look is given one more chance before the take
    // is written off.
    test('re-checks a zero byte file, and accepts it if the encoder lands',
        () async {
      final file = File(pathFor('late_flush.m4a'))..createSync();

      final gate = _hasValidAudioFile(file.path);
      file.writeAsBytesSync([1, 2, 3, 4]);

      expect(await gate, isTrue,
          reason: 'a late flush within the retry window must count');
    });

    // A stale path that redo already deleted must not be resurrected by the
    // retry: the second look re-checks existence, not just length.
    test('a file that is gone by the retry is rejected, not resurrected',
        () async {
      final file = File(pathFor('deleted.m4a'))..createSync();

      final gate = _hasValidAudioFile(file.path);

      // After the zero-length first look has been taken, inside the retry
      // window. Deleting before the call instead would settle at the first
      // existence check and never reach the branch under test.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      file.deleteSync();

      expect(await gate, isFalse);
    });
  });

  // -------------------------------------------------------------------
  // discardTake()'s delete — mirrored
  // -------------------------------------------------------------------
  //
  // Same reason: the delete only runs on a `_takePath` that `stopRecorder` set.
  // The take is deleted rather than orphaned because the participant has
  // explicitly rejected it, and the reference is dropped either way — the
  // sequence record -> stop -> redo -> record -> save used to persist the path
  // redo had just deleted.
  // -------------------------------------------------------------------
  group('discardTake() delete (mirrored)', () {
    late Directory audiosDir;

    setUp(() {
      audiosDir = Directory(
        p.join(Directory.systemTemp.createTempSync('redo').path, 'audios'),
      )..createSync(recursive: true);
    });

    tearDown(() {
      final root = audiosDir.parent;
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    test('deletes the take and drops the reference to it', () async {
      final take = File(p.join(audiosDir.path, 'first.m4a'))
        ..writeAsBytesSync([1, 2, 3]);

      expect(await _discardTake(take.path), isNull,
          reason: 'the reference must be dropped');
      expect(take.existsSync(), isFalse, reason: 'the take is deleted');
    });

    test('a take that is already gone is not an error', () async {
      expect(await _discardTake(p.join(audiosDir.path, 'missing.m4a')), isNull);
    });

    // Defence in depth: even if a stale reference survived, the gate in save()
    // must refuse it.
    test('the file gate still backstops a stale reference', () async {
      final take = File(p.join(audiosDir.path, 'first.m4a'))
        ..writeAsBytesSync([1, 2, 3]);
      final stalePath = take.path;

      await take.delete();

      expect(await _hasValidAudioFile(stalePath), isFalse);
    });
  });
}

/// Mirror of `AudioRecordingService._hasValidAudioFile`.
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

/// Mirror of the delete in `AudioRecordingService.discardTake`, returning the
/// path reference the service is left holding.
Future<String?> _discardTake(String? takePath) async {
  if (takePath == null) return null;

  final file = File(takePath);
  if (await file.exists()) {
    try {
      await file.delete();
    } catch (_) {
      // Logged and swallowed in the service: a take that cannot be deleted is
      // an orphaned file, not a reason to block the redo.
    }
  }

  return null;
}
