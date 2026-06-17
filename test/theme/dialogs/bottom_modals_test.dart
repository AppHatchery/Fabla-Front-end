import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
// Given the "no widget test, no impl change" constraint, this file
// contains two kinds of unit tests:
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
// What these tests DO NOT cover (would require DI or widget mount):
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
  //   } on Exception catch (_) {
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

    test('Error subtypes (not Exception) are NOT caught by `on Exception`',
        () async {
      // The implementation uses `on Exception` — narrower than `catch (_)`.
      // StateError extends Error, not Exception, so it must propagate.
      // This pins the type narrowness intentionally.
      await expectLater(
        () => harness.run(() async {
          throw StateError('not an Exception');
        }),
        throwsA(isA<StateError>()),
      );
      // Even when the body throws an Error, the guard must still release
      // via finally.
      expect(harness.guardHeld, isFalse,
          reason: 'finally runs even when the catch did not match');
    });
  });
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
    } on Exception {
      errorInvocations++;
    } finally {
      _recordingCheck = false;
    }
  }
}
