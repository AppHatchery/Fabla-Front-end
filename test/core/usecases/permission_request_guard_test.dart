import 'dart:async';

import 'package:audio_diaries_flutter/core/usecases/permission_request_guard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PermissionRequestGuard guard;
  late List<Object> reportedErrors;

  setUp(() {
    reportedErrors = <Object>[];
    guard = PermissionRequestGuard(onError: reportedErrors.add);
  });

  group('PermissionRequestGuard', () {
    test('runs the action once and resets isRunning when finished', () async {
      var calls = 0;
      expect(guard.isRunning, isFalse);

      await guard.run(() async {
        calls++;
      });

      expect(calls, 1);
      expect(guard.isRunning, isFalse);
      expect(reportedErrors, isEmpty);
    });

    test('is running while the action is in flight', () async {
      final gate = Completer<void>();

      final running = guard.run(() => gate.future);
      expect(guard.isRunning, isTrue);

      gate.complete();
      await running;
      expect(guard.isRunning, isFalse);
    });

    test('ignores concurrent calls while an action is in flight', () async {
      final gate = Completer<void>();
      var calls = 0;

      // First tap: increments, then blocks on the gate (stays in flight).
      final first = guard.run(() async {
        calls++;
        await gate.future;
      });

      // Second and third taps while the first is still in flight.
      await guard.run(() async {
        calls++;
      });
      await guard.run(() async {
        calls++;
      });

      expect(calls, 1, reason: 'overlapping requests must be ignored');

      gate.complete();
      await first;
      expect(guard.isRunning, isFalse);
    });

    test('allows a new run after the previous one completes', () async {
      var calls = 0;

      await guard.run(() async {
        calls++;
      });
      await guard.run(() async {
        calls++;
      });

      expect(calls, 2);
    });

    test('swallows the error, reports it, and does not rethrow', () async {
      final error = Exception('native channel failure');

      // Must complete normally rather than propagating the error.
      await guard.run(() async {
        throw error;
      });

      expect(reportedErrors, <Object>[error]);
      expect(guard.isRunning, isFalse);
    });

    test('recovers and runs again after a failed action', () async {
      var secondRan = false;

      await guard.run(() async {
        throw Exception('boom');
      });
      await guard.run(() async {
        secondRan = true;
      });

      expect(secondRan, isTrue);
      expect(reportedErrors, hasLength(1));
    });

    test('falls back to the default reporter without throwing', () async {
      final defaultGuard = PermissionRequestGuard();
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {};

      try {
        await defaultGuard.run(() async {
          throw Exception('boom');
        });
      } finally {
        debugPrint = originalDebugPrint;
      }

      expect(defaultGuard.isRunning, isFalse);
    });
  });
}
