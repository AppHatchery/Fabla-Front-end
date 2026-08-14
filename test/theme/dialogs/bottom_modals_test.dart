import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

// Unit tests for the recorder guard pattern used by
// `_BottomRecordingModalState.record()` in lib/theme/dialogs/bottom_modals.dart.
//
// ------------------------------------------------------------------
// Testability constraint
// ------------------------------------------------------------------
// `record()` is a private method on a private State (`_BottomRecordingModalState`).
// It cannot be invoked directly from a test. Without modifying the
// implementation to expose a seam (extract a controller, inject the
// FlutterSoundRecorder, expose `@visibleForTesting record()`), the only
// way to exercise it is by mounting the widget — which is a widget test,
// not a unit test, and trips a SIGABRT in flutter_tester because Rive's
// native binary is loaded via FFI when `_loadRive()` fires.
//
// Given the "no widget test, no impl change" constraint, this file mirrors
// each pattern under test with a stand-in harness. Groups 4 and 5 cover the
// data-loss fix: recordings were reaching the database for files that were
// never written to disk (Crashlytics issue ea6670918b178545b203745b920fee57),
// which then failed forever on playback and on S3 upload while the submission
// still committed to DynamoDB.
//
// The unit tests are:
//
//   1. FLUTTER_SOUND CONTRACT TESTS
//      Prove the underlying bug premise: calling `startRecorder` while
//      a recording is in flight throws `_RecorderRunningException` (which
//      surfaces as a PlatformException across the channel). This is what
//      crashed in production (Crashlytics issue
//      5330796079a5951a2da4212179a46f7b) and is what the `_recordingCheck`
//      guard is defending against.
//
//   2. GUARD PATTERN VERIFICATION TESTS
//      A stand-in function (`runWithRecordingGuard`) reproduces the exact
//      single-flight + try/catch/finally shape from `record()`. The tests
//      verify the pattern's properties:
//        - reentrant calls are no-ops while one is in flight
//        - the guard releases in `finally` even when the body throws
//        - the guard releases on early return paths (permission denied)
//      If `record()` strays from this pattern (e.g. the `finally` block
//      gets removed), the equivalent behavior would no longer hold.
//
//   3. basePath CONTRACT TESTS
//      The relative path stored on the Recording row must survive a
//      reinstall, so only the last two segments are kept.
//
//   4. SAVE GATE TESTS (`_SaveHarness`)
//      A recording is only persisted once the file is confirmed present and
//      non-empty. This is what stops a database row being created for audio
//      that does not exist.
//
//   5. REDO TESTS
//      redo() deletes the take on disk and drops the reference, so a later
//      save cannot resurrect the deleted path.
//
// What these tests DO NOT cover (would require DI or widget mount):
//   - `_restoreAudioSession()` on AppLifecycleState.resumed — it calls into
//     AudioSession.instance, which has no test seam here.
//   - The actual sequencing of `recorder.startRecorder/pauseRecorder/...`
//     inside `record()`.
//   - The interaction with `WakelockPlus`, `AudioSession`, the timer,
//     or `setState`.
//   - The Crashlytics-reported `_BottomRecordingModalState.record()` call
//     specifically.
// ------------------------------------------------------------------

const MethodChannel _flutterSoundChannel =
    MethodChannel('xyz.canardoux.flutter_sound_recorder');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // -------------------------------------------------------------------
  // 1. FlutterSoundRecorder contract tests
  // -------------------------------------------------------------------
  group('FlutterSoundRecorder contract — documents the bug premise', () {
    late List<MethodCall> calls;

    void setMock(Future<Object?>? Function(MethodCall) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_flutterSoundChannel, handler);
    }

    setUp(() {
      calls = [];
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_flutterSoundChannel, null);
    });

    test(
        'startRecorder surfaces PlatformException when native side reports '
        'a running recorder', () async {
      // The Crashlytics signature was:
      //   PlatformException(Recorder, _RecorderRunningException, ...)
      // Mock the channel to throw the same shape so callers downstream
      // know what they must catch.
      setMock((call) async {
        calls.add(call);
        if (call.method == 'startRecorder') {
          throw PlatformException(
            code: 'Recorder',
            message: "Instance of '_RecorderRunningException'",
          );
        }
        return null;
      });

      await expectLater(
        () async {
          // We bypass the FlutterSoundRecorder Dart-side state machine and
          // hit the channel directly — this is the layer at which the
          // exception originates in production.
          await _flutterSoundChannel.invokeMethod<dynamic>('startRecorder', {});
        },
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'Recorder')
            .having((e) => e.message ?? '', 'message',
                contains('_RecorderRunningException'))),
      );
    });

    test(
        'two channel-level startRecorder calls without a guard both reach '
        'the native side (the bug, before _recordingCheck)', () async {
      // No guard, no state machine — every call reaches the channel.
      // This is what the production code path looked like before the
      // fix: any reentrant trigger would land a second startRecorder
      // call on the native side and the second one threw.
      setMock((call) async {
        calls.add(call);
        return 'mock_path';
      });

      await _flutterSoundChannel.invokeMethod<dynamic>('startRecorder', {});
      await _flutterSoundChannel.invokeMethod<dynamic>('startRecorder', {});

      final startCalls =
          calls.where((c) => c.method == 'startRecorder').length;
      expect(startCalls, 2,
          reason: 'demonstrates: without the guard, two calls go through');
    });
  });

  // -------------------------------------------------------------------
  // 2. Guard pattern verification tests
  // -------------------------------------------------------------------
  //
  // `runWithRecordingGuard` mirrors the exact pattern used in
  // `_BottomRecordingModalState.record()`:
  //
  //   if (_recordingCheck) return;
  //   _recordingCheck = true;
  //   try {
  //     await body();
  //   } catch (e, s) {
  //     onError();
  //   } finally {
  //     _recordingCheck = false;
  //   }
  //
  // The tests below verify that this shape gives the protection the
  // implementation expects: reentrant suppression, exception swallowing,
  // and guard release on every exit path.
  // -------------------------------------------------------------------
  group('record() guard pattern — single-flight + try/catch/finally', () {
    late _GuardHarness harness;

    setUp(() {
      harness = _GuardHarness();
    });

    test('first call invokes the body exactly once', () async {
      await harness.run(() async {});
      expect(harness.bodyInvocations, 1);
      expect(harness.errorInvocations, 0);
      expect(harness.guardHeld, isFalse,
          reason: 'finally must release the flag');
    });

    test(
        'reentrant call while a body is in flight is suppressed and never '
        'reaches the body', () async {
      final gate = Completer<void>();
      // Kick off a long-running call. Don't await — we want to fire the
      // second call while the first is still parked.
      final first = harness.run(() async {
        await gate.future;
      });

      // Try to enter again before releasing the gate.
      await harness.run(() async {});
      expect(harness.bodyInvocations, 1,
          reason: '_recordingCheck must block the reentrant body');
      expect(harness.guardHeld, isTrue,
          reason: 'first call is still in flight');

      gate.complete();
      await first;
      expect(harness.guardHeld, isFalse,
          reason: 'finally clears the guard once the body resolves');
    });

    test('burst of N reentrant calls only runs the body once', () async {
      final gate = Completer<void>();
      final first = harness.run(() async {
        await gate.future;
      });

      // 50 reentrant attempts mid-flight — all must be suppressed.
      for (var i = 0; i < 50; i++) {
        await harness.run(() async {});
      }
      expect(harness.bodyInvocations, 1,
          reason: 'guard is O(1) regardless of burst size');

      gate.complete();
      await first;
    });

    test(
        'when body throws an Exception, error handler runs and guard '
        'releases (mirrors `catch + finally`)', () async {
      await harness.run(() async {
        throw const FormatException('simulated');
      });

      expect(harness.bodyInvocations, 1);
      expect(harness.errorInvocations, 1,
          reason: 'catch on Exception must fire');
      expect(harness.guardHeld, isFalse,
          reason: 'finally must release even when body throws');
    });

    test(
        'PlatformException from body is caught (matches the production '
        'crash shape)', () async {
      await harness.run(() async {
        throw PlatformException(
          code: 'Recorder',
          message: "Instance of '_RecorderRunningException'",
        );
      });

      expect(harness.errorInvocations, 1);
      expect(harness.guardHeld, isFalse);
    });

    test(
        'after an exception in body, a subsequent call IS allowed '
        '(guard cleared in finally)', () async {
      // First call throws — guard must release.
      await harness.run(() async {
        throw const FormatException('first fail');
      });
      // Second call must be allowed through.
      await harness.run(() async {});

      expect(harness.bodyInvocations, 2,
          reason: 'finally must release the guard so retries are allowed');
      expect(harness.errorInvocations, 1);
    });

    test(
        'early return inside body (e.g. permission denied) still releases '
        'the guard', () async {
      // Simulate the permission-denied branch: body returns immediately.
      await harness.run(() async {
        return; // early return, no throw
      });
      // Second call must be unaffected.
      await harness.run(() async {});

      expect(harness.bodyInvocations, 2);
      expect(harness.guardHeld, isFalse,
          reason: 'finally runs on all exit paths, including early return');
    });

    test('Error subtypes are caught — the catch is deliberately unnarrowed',
        () async {
      // `record()` used `on Exception`, which let FlutterError, TypeError and
      // LateInitializationError escape as uncaught async errors — they reached
      // PlatformDispatcher.onError and were reported as fatal crashes.
      //
      // It now uses `catch (e, s)` so those are caught and reported as
      // non-fatals instead. StateError extends Error, not Exception, so it
      // pins the widening.
      await harness.run(() async {
        throw StateError('an Error, not an Exception');
      });

      expect(harness.errorInvocations, 1,
          reason: 'Error subtypes must reach the catch and be reported');
      expect(harness.guardHeld, isFalse,
          reason: 'finally runs on every exit path');
    });
  });

  // -------------------------------------------------------------------
  // 3. basePath — the relative path stored on the Recording row
  // -------------------------------------------------------------------
  //
  // `save()` persists `basePath(file.path)`, not the absolute path. Keeping
  // only the last two segments makes the reference survive reinstalls,
  // because the iOS container UUID in the absolute path changes.
  //
  // Mirrored below rather than imported, for the same reason the rest of this
  // file avoids importing bottom_modals.dart.
  // -------------------------------------------------------------------
  group('basePath contract', () {
    test('keeps the final directory and filename', () {
      expect(
        _basePath('/var/mobile/Containers/Data/Application/B2AD9040/Documents/'
            'audios/audio_prompt_120_2026-07-21-20-55-36.aac'),
        'audios/audio_prompt_120_2026-07-21-20-55-36.aac',
      );
    });

    test('drops the container UUID that changes between installs', () {
      const first = '/var/mobile/Containers/Data/Application/AAAA-1111/'
          'Documents/audios/clip.aac';
      const second = '/var/mobile/Containers/Data/Application/BBBB-2222/'
          'Documents/audios/clip.aac';

      expect(_basePath(first), _basePath(second));
    });

    test('handles a two segment path', () {
      expect(_basePath('audios/clip.aac'), 'audios/clip.aac');
    });
  });

  // -------------------------------------------------------------------
  // 4. save() validation gate
  // -------------------------------------------------------------------
  //
  // `save()` used to persist `tempUrl` unconditionally. flutter_sound creates
  // the file lazily on first audio write, so an inactive audio session left a
  // valid-looking path pointing at nothing — the row reached the database and
  // then failed forever on playback and on S3 upload, while the submission
  // still committed to DynamoDB.
  //
  // `_SaveHarness` mirrors the gate now in `save()`. If the implementation
  // changes, mirror it here AND update these tests.
  // -------------------------------------------------------------------
  group('save() validation gate', () {
    late Directory audiosDir;
    late _SaveHarness harness;

    setUp(() {
      // Mirrors <documents>/audios/, so basePath yields "audios/<file>".
      audiosDir = Directory(
        p.join(Directory.systemTemp.createTempSync('save_gate').path, 'audios'),
      )..createSync(recursive: true);

      harness = _SaveHarness();
    });

    tearDown(() {
      final root = audiosDir.parent;
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    String pathFor(String name) => p.join(audiosDir.path, name);

    test('persists a recording that exists and has content', () async {
      final file = File(pathFor('clip.aac'))..writeAsBytesSync([1, 2, 3, 4]);

      await harness.save(file.path);

      expect(harness.savedName, 'audios/clip.aac');
      expect(harness.popped, isTrue);
    });

    test('does not persist when the file was never written', () async {
      // The production case: startRecorder captured nothing so the file was
      // never created, but stopRecorder still returned its intended path.
      await harness.save(pathFor('never_written.aac'));

      expect(harness.savedName, isNull,
          reason: 'a database row must not be created for a missing file');
      expect(harness.popped, isFalse,
          reason: 'the modal stays open so the participant can retry');
    });

    test('does not persist a zero byte file', () async {
      final file = File(pathFor('empty.aac'))..createSync();

      await harness.save(file.path);

      expect(file.lengthSync(), 0);
      expect(harness.savedName, isNull);
      expect(harness.popped, isFalse);
    });

    test('clears tempUrl on failure so a retry cannot reuse the bad path',
        () async {
      await harness.save(pathFor('missing.aac'));

      expect(harness.tempUrl, isNull);
    });

    test('does nothing when there is no recording to save', () async {
      await harness.save(null);

      expect(harness.savedName, isNull);
      expect(harness.popped, isFalse);
    });
  });

  // -------------------------------------------------------------------
  // 5. redo() must clear tempUrl
  // -------------------------------------------------------------------
  //
  // redo() deletes the file at tempUrl but used to leave the field set. The
  // sequence record -> stop -> redo -> record -> tap save then persisted the
  // path redo had just deleted.
  // -------------------------------------------------------------------
  group('redo() discards the previous take', () {
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

    /// redo(): delete the take on disk, then drop the reference to it.
    Future<String?> redo(String? tempUrl) async {
      if (tempUrl != null) {
        final file = File(tempUrl);
        if (await file.exists()) await file.delete();
      }
      return null;
    }

    test('clearing tempUrl leaves nothing for a later save to persist',
        () async {
      final first = File(p.join(audiosDir.path, 'first.aac'))
        ..writeAsBytesSync([1, 2, 3]);

      final harness = _SaveHarness();
      final afterRedo = await redo(first.path);

      expect(afterRedo, isNull, reason: 'redo must drop the reference');
      expect(first.existsSync(), isFalse, reason: 'redo deletes the take');

      await harness.save(afterRedo);

      expect(harness.savedName, isNull);
      expect(harness.popped, isFalse);
    });

    test('the existence check still backstops a stale tempUrl', () async {
      // Defence in depth: even if a stale reference survived redo, the gate
      // in save() must refuse it.
      final first = File(p.join(audiosDir.path, 'first.aac'))
        ..writeAsBytesSync([1, 2, 3]);
      final stalePath = first.path;

      await first.delete();

      final harness = _SaveHarness();
      await harness.save(stalePath);

      expect(harness.savedName, isNull);
      expect(harness.tempUrl, isNull);
    });
  });
}

/// Mirror of `basePath` in bottom_modals.dart — the last two path segments.
String _basePath(String path) {
  final parts = p.split(path);
  return parts.sublist(parts.length - 2).join(p.separator);
}


/// Mirror of the `_recordingCheck + try/catch/finally` pattern used by
/// `_BottomRecordingModalState.record()`. Tests use this to exercise the
/// pattern's properties without needing widget mounting or DI.
///
/// If you change the pattern in `record()`, mirror the change here AND
/// update the tests — otherwise the spec drifts away from the impl.
class _GuardHarness {
  bool _recordingCheck = false;
  int bodyInvocations = 0;
  int errorInvocations = 0;

  bool get guardHeld => _recordingCheck;

  Future<void> run(Future<void> Function() body) async {
    if (_recordingCheck) return;
    _recordingCheck = true;
    try {
      bodyInvocations++;
      await body();
    } catch (_) {
      // Deliberately unnarrowed: `record()` catches Error subtypes too, so
      // FlutterError/TypeError are reported rather than escaping to
      // PlatformDispatcher.onError as fatal crashes.
      errorInvocations++;
    } finally {
      _recordingCheck = false;
    }
  }
}

/// Mirror of the validation gate in `_BottomRecordingModalState.save()`:
///
///   final url = tempUrl;
///   if (url == null) return;
///   final file = File(url);
///   if (!await file.exists() || await file.length() == 0) {
///     tempUrl = null;
///     ...report, reset...
///     return;
///   }
///   widget.onSave?.call(basePath(file.path));
///   if (mounted) Navigator.pop(context);
///
/// If you change the gate in `save()`, mirror the change here AND update the
/// tests — otherwise the spec drifts away from the impl.
class _SaveHarness {
  String? tempUrl;
  String? savedName;
  bool popped = false;

  Future<void> save(String? url) async {
    tempUrl = url;
    if (url == null) return;

    final file = File(url);
    if (!await file.exists() || await file.length() == 0) {
      tempUrl = null;
      return;
    }

    savedName = _basePath(file.path);
    popped = true;
  }
}
