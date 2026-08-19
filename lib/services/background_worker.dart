import 'dart:developer' as dev;
import 'package:audio_diaries_flutter/core/usecases/diary_health_monitor.dart';
import 'package:workmanager/workmanager.dart';
import 'package:audio_diaries_flutter/core/usecases/diary_health_check.dart';

/// Unique identifier for the proof-of-concept periodic worker.
///
/// Used as both the WorkManager `uniqueName` and `taskName`. On iOS this string
/// is submitted to BGTaskScheduler, so the same value must be listed in
/// `ios/Runner/Info.plist` under `BGTaskSchedulerPermittedIdentifiers`.
const String pocWorkerTask = 'edu.emory.audio_diaries_flutter.pocWorker';

/// Background isolate entry point.
///
/// Must be a top-level function annotated with `@pragma('vm:entry-point')` so it
/// survives tree-shaking and can be started by the OS when a task is due. It
/// runs in a separate isolate from the UI.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    DiaryHealthMonitor.run();
    return Future.value(true);
  });
}

/// Registers the WorkManager callback and schedules the POC periodic task.
///
/// Android enforces a 15-minute minimum for periodic work; shorter frequencies
/// are clamped to 15 minutes by the OS. Re-registering on each launch is safe:
/// the default periodic policy keeps the existing scheduled task.
Future<void> initBackgroundWorker() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    pocWorkerTask,
    pocWorkerTask,
    frequency: const Duration(hours: 24),
  );
}
