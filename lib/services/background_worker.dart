import 'dart:developer' as dev;
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/core/usecases/diary_health_check.dart';
import 'package:audio_diaries_flutter/core/usecases/diary_health_monitor.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/main.dart' show objectbox;

/// Unique identifier for the proof-of-concept periodic worker.
///
/// Used as both the WorkManager `uniqueName` and `taskName`. On iOS this string
/// is submitted to BGTaskScheduler, so the same value must be listed in
/// `ios/Runner/Info.plist` under `BGTaskSchedulerPermittedIdentifiers`.
const String pocWorkerTask = 'edu.emory.audio_diaries_flutter.pocWorker';

/// How often the OS is asked to run [pocWorkerTask].
///
/// Must stay at or above [minimumPeriodicFrequency]; WorkManager silently
/// clamps anything shorter.
const Duration pocWorkerFrequency = Duration(hours: 24);

/// Android's `PeriodicWorkRequest.MIN_PERIODIC_INTERVAL_MILLIS`.
const Duration minimumPeriodicFrequency = Duration(minutes: 15);

/// Opens (or attaches to) the ObjectBox store the task reads from.
typedef StoreOpener = Future<ObjectBox> Function();

/// Evaluates on-device diaries and returns whatever it flagged.
typedef HealthChecker = Future<List<DiaryHealthIssue>> Function();

/// The work [pocWorkerTask] performs, as a named function so it can be unit
/// tested without a background isolate or platform channels.
///
/// Runs in a **separate isolate** from the UI, where `main()` never executed, so
/// nothing is set up. Every dependency the task touches is initialized here:
///  - [WidgetsFlutterBinding.ensureInitialized] wires up plugin channels
///    (path_provider — used by both ObjectBox and the report writer).
///  - [openStore] sets the [objectbox] global that the repositories read; the
///    default attaches to the already-open store when the app process is alive
///    and opens a fresh one otherwise.
///
/// Never throws. An uncaught error here surfaces as an isolate crash rather
/// than a task result, so failures are converted to `false` and reported.
///
/// Returns `true` when the check completed — finding issues is a successful
/// run, not a failure — and `false` when it could not complete.
Future<bool> runPocWorkerTask({
  StoreOpener openStore = ObjectBox.create,
  HealthChecker? runHealthCheck,
}) async {
  try {
    dev.log('starting check', name: 'healthCheck');
    WidgetsFlutterBinding.ensureInitialized();
    objectbox = await openStore();

    final check = runHealthCheck ?? () => DiaryHealthMonitor().run();
    final issues = await check();

    dev.log('Health Check Done: ${issues.length} issue(s)', name: 'healthCheck');
    for (final issue in issues) {
      dev.log(issue.toString(), name: 'healthCheck');
    }
    return true;
  } catch (error, stackTrace) {
    dev.log('Health Check failed: $error',
        name: 'healthCheck', error: error, level: 1000);
    await CrashlyticsService()
        .recordError(error, stackTrace, reason: '$pocWorkerTask failed');
    return false;
  }
}

/// Background isolate entry point.
///
/// Must be a top-level function annotated with `@pragma('vm:entry-point')` so it
/// survives tree-shaking and can be started by the OS when a task is due.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) => runPocWorkerTask());
}

/// Hands the background isolate entry point to the OS scheduler.
typedef EntryPointRegistrar = Future<void> Function(Function entryPoint);

/// Asks the OS to run [taskName] roughly every [frequency].
typedef PeriodicTaskScheduler = Future<void> Function(
    String uniqueName, String taskName, Duration frequency);

Future<void> _registerEntryPoint(Function entryPoint) =>
    Workmanager().initialize(entryPoint);

Future<void> _schedulePeriodicTask(
  String uniqueName,
  String taskName,
  Duration frequency,
) {
  return Workmanager().registerPeriodicTask(
    uniqueName,
    taskName,
    frequency: frequency,
  );
}

/// Registers the WorkManager callback and schedules the POC periodic task.
///
/// Never throws. This runs on the launch path, so a scheduler failure must cost
/// the participant a background health check, not the app.
///
/// [registerEntryPoint] and [schedulePeriodicTask] are injectable so tests can
/// observe what gets scheduled without touching platform channels.
Future<void> initBackgroundWorker({
  EntryPointRegistrar registerEntryPoint = _registerEntryPoint,
  PeriodicTaskScheduler schedulePeriodicTask = _schedulePeriodicTask,
}) async {
  try {
    await registerEntryPoint(callbackDispatcher);
    await schedulePeriodicTask(pocWorkerTask, pocWorkerTask, pocWorkerFrequency);
  } catch (error, stackTrace) {
    dev.log('Failed to schedule $pocWorkerTask: $error',
        name: 'healthCheck', error: error, level: 1000);
    await CrashlyticsService().recordError(error, stackTrace,
        reason: 'Failed to schedule $pocWorkerTask');
  }
}
