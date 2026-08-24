// BackgroundWorker Unit Tests
// -----------------------------------------------------------------------------
// Covers the three things that can silently break the POC health-check worker:
//   1. The task body (runPocWorkerTask) — what actually runs in the background
//      isolate. Its dependencies are injected so no ObjectBox native library or
//      platform channel is touched.
//   2. The scheduling contract (initBackgroundWorker) — unique name, task name,
//      frequency, and call ordering, observed through injected scheduler seams.
//   3. The iOS BGTaskScheduler identifier contract — iOS drops a submitted task
//      whose identifier is missing from Info.plist, and it fails silently.
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/core/usecases/diary_health_check.dart';
import 'package:audio_diaries_flutter/main.dart' show objectbox;
import 'package:audio_diaries_flutter/services/background_worker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockObjectBox extends Mock implements ObjectBox {}

/// Records what [initBackgroundWorker] asks the OS to do, in order.
class _RecordingScheduler {
  final List<String> calls = <String>[];
  Function? entryPoint;
  String? uniqueName;
  String? taskName;
  Duration? frequency;

  Object? registerError;
  Object? scheduleError;

  Future<void> registerEntryPoint(Function entryPoint) async {
    calls.add('registerEntryPoint');
    this.entryPoint = entryPoint;
    if (registerError != null) throw registerError!;
  }

  Future<void> schedulePeriodicTask(
      String uniqueName, String taskName, Duration frequency) async {
    calls.add('schedulePeriodicTask');
    this.uniqueName = uniqueName;
    this.taskName = taskName;
    this.frequency = frequency;
    if (scheduleError != null) throw scheduleError!;
  }
}

DiaryHealthIssue _issue({String ruleId = 'rule.test'}) => DiaryHealthIssue(
      ruleId: ruleId,
      severity: HealthSeverity.warning,
      message: 'test issue',
      studyID: 1,
      studyName: 'Test Study',
      diaryId: 2,
      diaryName: 'Test Diary',
    );

Future<void> _runWith(_RecordingScheduler scheduler) => initBackgroundWorker(
      registerEntryPoint: scheduler.registerEntryPoint,
      schedulePeriodicTask: scheduler.schedulePeriodicTask,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runPocWorkerTask', () {
    late MockObjectBox store;

    setUp(() => store = MockObjectBox());

    test('returns true and publishes the opened store to the objectbox global',
        () async {
      final result = await runPocWorkerTask(
        openStore: () async => store,
        runHealthCheck: () async => const <DiaryHealthIssue>[],
      );

      expect(result, isTrue);
      expect(objectbox, same(store));
    });

    test('opens the store before running the health check', () async {
      // The monitor reads diaries through ObjectBox, so a check that ran first
      // would either throw or read a stale store.
      final order = <String>[];

      await runPocWorkerTask(
        openStore: () async {
          order.add('openStore');
          return store;
        },
        runHealthCheck: () async {
          order.add('runHealthCheck');
          return const <DiaryHealthIssue>[];
        },
      );

      expect(order, ['openStore', 'runHealthCheck']);
    });

    test('returns true when the check finds issues', () async {
      // Finding issues is a completed run, not a failed task — returning false
      // would make WorkManager retry a check that already succeeded.
      final result = await runPocWorkerTask(
        openStore: () async => store,
        runHealthCheck: () async => [_issue(), _issue(ruleId: 'rule.other')],
      );

      expect(result, isTrue);
    });

    test('returns false without rethrowing when the store fails to open',
        () async {
      final result = await runPocWorkerTask(
        openStore: () async => throw Exception('store unavailable'),
        runHealthCheck: () async => const <DiaryHealthIssue>[],
      );

      expect(result, isFalse);
    });

    test('returns false when the store opener throws synchronously', () async {
      final result = await runPocWorkerTask(
        openStore: () => throw Exception('synchronous failure'),
        runHealthCheck: () async => const <DiaryHealthIssue>[],
      );

      expect(result, isFalse);
    });

    test('skips the health check when the store fails to open', () async {
      var checkRan = false;

      await runPocWorkerTask(
        openStore: () async => throw Exception('store unavailable'),
        runHealthCheck: () async {
          checkRan = true;
          return const <DiaryHealthIssue>[];
        },
      );

      expect(checkRan, isFalse);
    });

    test('returns false without rethrowing when the health check throws',
        () async {
      final result = await runPocWorkerTask(
        openStore: () async => store,
        runHealthCheck: () async => throw StateError('check exploded'),
      );

      expect(result, isFalse);
    });
  });

  group('initBackgroundWorker', () {
    late _RecordingScheduler scheduler;

    setUp(() => scheduler = _RecordingScheduler());

    test('registers the top-level callbackDispatcher entry point', () async {
      // Must be the top-level function itself: a closure or bound method is
      // tree-shaken out of the background isolate and the task never fires.
      await _runWith(scheduler);

      expect(scheduler.entryPoint, same(callbackDispatcher));
    });

    test('schedules one periodic task using the POC identifier for both names',
        () async {
      await _runWith(scheduler);

      expect(scheduler.uniqueName, pocWorkerTask);
      expect(scheduler.taskName, pocWorkerTask);
      expect(scheduler.frequency, pocWorkerFrequency);
      expect(
        scheduler.calls.where((call) => call == 'schedulePeriodicTask').length,
        1,
      );
    });

    test('registers the entry point before scheduling the task', () async {
      // Scheduling first can fire a task before the callback is wired up.
      await _runWith(scheduler);

      expect(scheduler.calls, ['registerEntryPoint', 'schedulePeriodicTask']);
    });

    test('does not throw when entry point registration fails', () async {
      // This runs on the launch path in main(); a scheduler failure must not
      // block runApp().
      scheduler.registerError = Exception('scheduler unavailable');

      await expectLater(_runWith(scheduler), completes);
    });

    test('does not schedule the task when entry point registration fails',
        () async {
      scheduler.registerError = Exception('scheduler unavailable');

      await _runWith(scheduler);

      expect(scheduler.calls, ['registerEntryPoint']);
    });

    test('does not throw when scheduling the periodic task fails', () async {
      scheduler.scheduleError = Exception('quota exceeded');

      await expectLater(_runWith(scheduler), completes);
    });
  });

  group('scheduling constants', () {
    test('frequency is at or above the minimum WorkManager honours', () {
      // WorkManager silently clamps a shorter interval, which would make the
      // configured schedule a lie rather than an error.
      expect(pocWorkerFrequency, greaterThanOrEqualTo(minimumPeriodicFrequency));
    });

    test('frequency is 24 hours', () {
      expect(pocWorkerFrequency, const Duration(hours: 24));
    });

    test('task identifier is reverse-DNS and app-scoped', () {
      // BGTaskScheduler rejects identifiers outside the app's bundle prefix.
      expect(pocWorkerTask, startsWith('edu.emory.audio_diaries_flutter.'));
    });
  });

  group('iOS BGTaskScheduler registration', () {
    test('pocWorkerTask is listed in Info.plist permitted identifiers', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();

      final keyStart =
          plist.indexOf('<key>BGTaskSchedulerPermittedIdentifiers</key>');
      expect(keyStart, isNonNegative,
          reason: 'Info.plist is missing BGTaskSchedulerPermittedIdentifiers');

      final arrayEnd = plist.indexOf('</array>', keyStart);
      expect(arrayEnd, isNonNegative,
          reason: 'BGTaskSchedulerPermittedIdentifiers array is unterminated');

      expect(
        plist.substring(keyStart, arrayEnd),
        contains('<string>$pocWorkerTask</string>'),
        reason: 'Add $pocWorkerTask to BGTaskSchedulerPermittedIdentifiers',
      );
    });
  });
}
