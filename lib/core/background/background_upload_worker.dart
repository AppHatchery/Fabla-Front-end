import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/core/background/upload_execution_lock.dart';
import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/firebase_options.dart';
import 'package:audio_diaries_flutter/main.dart' as app;
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/summary_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/notification_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'background_upload_manager.dart';

@pragma('vm:entry-point')
void backgroundUploadDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != BackgroundUploadManager.taskIdentifier) return true;

    WidgetsFlutterBinding.ensureInitialized();
    _workerLog('Started');
    final backgroundUploads = BackgroundUploadManager();
    await backgroundUploads.scheduleRetry();

    final lock = UploadExecutionLock();
    String? token;

    try {
      token = await lock.acquire();
      if (token == null) {
        _workerLog('Another upload owns the execution lock; requesting retry');
        // Returning false asks android WorkManager to retry with backoff. The
        // next iOS processing request was already queued above.
        return false;
      }

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      await CrashlyticsService().initialize();
      await CrashlyticsService().log('Background upload worker initialized');
      await _initializeNotifications();
      app.objectbox = await ObjectBox.create();

      final diaryRepository = DiaryRepository();
      final pending = await diaryRepository.getAllPending();
      _workerLog('Found ${pending.length} pending diary upload(s)');
      await CrashlyticsService()
          .log('Background worker found ${pending.length} pending upload(s)');
      if (pending.isEmpty) {
        await _cancelNextIosAttempt(backgroundUploads);
        return true;
      }

      // Android displays WorkManager's foreground-service notification while
      // this worker runs.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _showUploadNotification(
          id: 90420,
          title: 'Uploading diary',
          body: pending.length == 1
              ? 'Fabla is uploading your diary.'
              : 'Fabla is uploading ${pending.length} diaries.',
          payload: const {'type': 'background_upload_started'},
        );
      }

      final summaryRepository = SummaryRepository();
      var allUploaded = true;
      for (final diary in pending) {
        _workerLog('Uploading pending diary ${diary.id}');
        final uploaded = await summaryRepository.submitDiary(
          diary,
          scheduleBackgroundRetry: false,
          acquireExecutionLock: false,
          allowPlatformLocationLookup: false,
        );
        _workerLog('Diary ${diary.id} upload result: $uploaded');
        await CrashlyticsService()
            .log('Background diary ${diary.id} upload result: $uploaded');
        allUploaded = allUploaded && uploaded == true;
      }
      if (allUploaded) {
        await PreferenceService()
            .setBoolPreference(key: 'network_error', value: false);
        await _showUploadNotification(
          id: 90421,
          title: pending.length == 1
              ? 'Diary upload complete'
              : 'Diary uploads complete',
          body: pending.length == 1
              ? 'Your diary was uploaded successfully.'
              : '${pending.length} diaries were uploaded successfully.',
          payload: const {'type': 'background_upload_complete'},
        );
        await _cancelNextIosAttempt(backgroundUploads);
      }
      return allUploaded;
    } catch (error, stackTrace) {
      dev.log(
        'Background upload failed: $error',
        name: 'BackgroundUploadWorker',
        stackTrace: stackTrace,
      );
      await CrashlyticsService().recordError(
        error,
        stackTrace,
        reason: 'Workmanager background upload failed',
      );
      return false;
    } finally {
      if (token != null) await lock.release(token);
    }
  });
}

Future<void> _initializeNotifications() async {
  try {
    await NotificationService.init();
  } catch (error, stackTrace) {
    _workerLog('Could not initialize upload notifications: $error');
    await CrashlyticsService().recordError(
      error,
      stackTrace,
      reason: 'Background upload notification initialization failed',
    );
  }
}

Future<void> _showUploadNotification({
  required int id,
  required String title,
  required String body,
  required Map<String, String> payload,
}) async {
  try {
    await NotificationService.showImmediateNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  } catch (error, stackTrace) {
    // A disabled/broken notification channel must never turn a successful
    // diary upload into a failed WorkManager result.
    _workerLog('Could not display upload notification: $error');
    await CrashlyticsService().recordError(
      error,
      stackTrace,
      reason: 'Background upload notification failed',
    );
  }
}

/// iOS queues a separate future BGProcessing request when the worker starts,
/// so it must be cancelled after success. Android's one-off worker is the job
/// currently executing; cancelling it here can terminate it before WorkManager
/// records success and removes its foreground notification cleanly.
Future<void> _cancelNextIosAttempt(BackgroundUploadManager manager) async {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await manager.cancelRetryIfQueueIsEmpty();
  }
}

void _workerLog(String message) {
  dev.log(message, name: 'BackgroundUploadWorker');
  debugPrint('BackgroundUploadWorker: $message');
}
