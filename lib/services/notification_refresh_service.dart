import 'dart:developer' as dev;
import 'dart:ui' show DartPluginRegistrant;

import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/core/usecases/notification_manager.dart';
import 'package:audio_diaries_flutter/firebase_options.dart';
import 'package:audio_diaries_flutter/main.dart' as app;
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

/// Keeps the rolling window of scheduled reminders topped up while the app is
/// not opened.
///
/// Only [threshold] reminders are scheduled ahead (iOS caps pending
/// notifications at 64), so a participant who never opens the app would run
/// out. This periodic task re-runs [NotificationManager.sync] in the
/// background. The OS decides when it actually runs (Android roughly every
/// [_frequency]; iOS based on app usage), so the last scheduled reminder also
/// asks the participant to open the app.
class NotificationRefreshService {
  /// Also listed in ios/Runner/Info.plist BGTaskSchedulerPermittedIdentifiers
  /// and registered in AppDelegate.swift.
  static const taskId = 'edu.emory.audio_diaries.refreshNotifications';
  static const _frequency = Duration(hours: 6);

  /// Registers the periodic task. Safe to call on every launch.
  static Future<void> register() async {
    try {
      await Workmanager().initialize(notificationRefreshDispatcher);
      await Workmanager().registerPeriodicTask(
        taskId,
        taskId,
        frequency: _frequency,
        initialDelay: _frequency,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e, stack) {
      dev.log('Registering notification refresh failed: $e');
      await CrashlyticsService().recordError(e, stack,
          reason: 'NotificationRefreshService.register failed');
    }
  }
}

/// Background entry point; runs in its own isolate.
@pragma('vm:entry-point')
void notificationRefreshDispatcher() {
  Workmanager().executeTask((task, _) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      }
      await CrashlyticsService().initialize();
      app.objectbox = await ObjectBox.create();
      await NotificationService.init();
      await NotificationManager()
          .sync(page: NotificationManager.backgroundPage);
      return true;
    } catch (e, stack) {
      dev.log('Background notification refresh failed: $e');
      await CrashlyticsService().recordError(e, stack,
          reason: 'Background notification refresh failed');
      return false;
    }
  });
}
