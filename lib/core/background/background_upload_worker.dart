import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/core/background/upload_execution_lock.dart';
import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/firebase_options.dart';
import 'package:audio_diaries_flutter/main.dart' as app;
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/summary_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:firebase_core/firebase_core.dart';
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
      app.objectbox = await ObjectBox.create();

      final diaryRepository = DiaryRepository();
      final pending = await diaryRepository.getAllPending();
      _workerLog('Found ${pending.length} pending diary upload(s)');
      await CrashlyticsService()
          .log('Background worker found ${pending.length} pending upload(s)');
      if (pending.isEmpty) {
        await backgroundUploads.cancelRetryIfQueueIsEmpty();
        return true;
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
        await backgroundUploads.cancelRetryIfQueueIsEmpty();
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

void _workerLog(String message) {
  dev.log(message, name: 'BackgroundUploadWorker');
  debugPrint('BackgroundUploadWorker: $message');
}
