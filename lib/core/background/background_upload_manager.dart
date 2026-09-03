import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'background_upload_worker.dart';

class BackgroundUploadManager {
  static const taskIdentifier = 'edu.emory.audio.diaries.backgroundUpload';
  static const _androidUniqueName = 'fabla-background-upload';

  Future<void> initialize() =>
      Workmanager().initialize(backgroundUploadDispatcher);

  /// Schedules upload recovery.
  ///
  /// [immediate] is used after a foreground submission finds that the device
  /// is offline. On Android it replaces the delayed safety task with
  /// expedited work which waits only for a network connection.
  Future<void> scheduleRetry({bool immediate = false}) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await Workmanager().registerProcessingTask(
          taskIdentifier,
          taskIdentifier,
          constraints: Constraints(networkType: NetworkType.connected),
        );
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        await Workmanager().registerOneOffTask(
          _androidUniqueName,
          taskIdentifier,
          initialDelay: immediate ? null : const Duration(seconds: 30),
          constraints: Constraints(networkType: NetworkType.connected),
          existingWorkPolicy:
              immediate ? ExistingWorkPolicy.replace : ExistingWorkPolicy.keep,
          backoffPolicy: BackoffPolicy.exponential,
          // A transient lock, network transition, or credential refresh should
          // not leave a diary waiting for fifteen minutes. Repeated failures
          // still spread out because the policy is exponential.
          backoffPolicyDelay: const Duration(seconds: 30),
          expedited: immediate,
          outOfQuotaPolicy:
              immediate ? OutOfQuotaPolicy.runAsNonExpeditedWorkRequest : null,
          foregroundServiceConfig: ForegroundServiceConfig(
            notificationTitle: 'Uploading diary',
            notificationText: 'Fabla is safely uploading your diary.',
            foregroundServiceType: ForegroundServiceType.dataSync,
          ),
        );
      }
    } catch (error, stackTrace) {
      dev.log(
        'Unable to schedule background upload: $error',
        name: 'BackgroundUploadManager',
        stackTrace: stackTrace,
      );
      await CrashlyticsService().recordError(
        error,
        stackTrace,
        reason: 'Unable to schedule Workmanager background upload',
      );
    }
  }

  /// Restores recovery scheduling after an app update, reboot, or force-stop.
  Future<void> schedulePendingUploads() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    final hasPending = DiaryRepository()
        .getAllDiaries()
        .any((diary) => diary.status == DiaryStatus.complete);
    // Replace any stale/backed-off Android job left by an older app run. iOS
    // ignores the immediate hint and registers its normal processing request.
    if (hasPending) await scheduleRetry(immediate: true);
  }

  Future<void> cancelRetryIfQueueIsEmpty() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    final hasPending = DiaryRepository()
        .getAllDiaries()
        .any((diary) => diary.status == DiaryStatus.complete);
    if (hasPending) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await Workmanager().cancelByUniqueName(taskIdentifier);
      } else {
        await Workmanager().cancelByUniqueName(_androidUniqueName);
      }
    } catch (error, stackTrace) {
      dev.log(
        'Unable to cancel completed background upload: $error',
        name: 'BackgroundUploadManager',
        stackTrace: stackTrace,
      );
      await CrashlyticsService().recordError(
        error,
        stackTrace,
        reason: 'Unable to cancel completed Workmanager upload',
      );
    }
  }
}
