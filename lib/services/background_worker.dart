import 'dart:developer' as dev;
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/core/usecases/diary_health_monitor.dart';
import 'package:audio_diaries_flutter/main.dart' show objectbox;

/// Unique identifier for the proof-of-concept periodic worker.
///
/// Used as both the WorkManager `uniqueName` and `taskName`. On iOS this string
/// is submitted to BGTaskScheduler, so the same value must be listed in
/// `ios/Runner/Info.plist` under `BGTaskSchedulerPermittedIdentifiers`.
const String pocWorkerTask = 'edu.emory.audio_diaries_flutter.pocWorker';

/// Background isolate entry point.
///
/// Runs in a **separate isolate** from the UI, where `main()` never executed, so
/// nothing is set up. Every dependency the task touches must be initialized here
/// before use:
///  - `WidgetsFlutterBinding.ensureInitialized()` wires up plugin channels
///    (path_provider — used by both ObjectBox and the report writer).
///  - `ObjectBox.create()` sets the `objectbox` global that the repositories
///    read; it attaches to the already-open store when the app process is alive
///    and opens a fresh one otherwise.
///
/// Must be a top-level function annotated with `@pragma('vm:entry-point')` so it
/// survives tree-shaking and can be started by the OS when a task is due.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    dev.log('starting check', name: 'healthCheck');
    WidgetsFlutterBinding.ensureInitialized();
    objectbox = await ObjectBox.create();

    final issues = await DiaryHealthMonitor().run();
    dev.log('Health Check Done: ${issues.length} issue(s)', name: 'healthCheck');
    for (final issue in issues) {
      dev.log(issue.toString(), name: 'healthCheck');
    }
    return Future.value(true);
  });
}

/// Registers the WorkManager callback and schedules the POC periodic task.
Future<void> initBackgroundWorker() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    pocWorkerTask,
    pocWorkerTask,
    frequency: const Duration(hours: 24),
  );
}
