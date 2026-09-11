import 'dart:io';

import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// The Android microphone foreground service that keeps a take alive while the
/// app is off screen.
///
/// Android revokes the microphone from a backgrounded app with no
/// microphone-typed foreground service, while flutter_sound keeps writing
/// regardless — so without this a take captures silence for the time spent
/// away, and nothing downstream can tell.
///
/// A no-op on iOS, which keeps capturing on the `audio` background mode alone.
class RecordingForegroundService {
  /// Notification id for this service. Distinct from the ids the alarm and
  /// reminder notifications use so it cannot replace one of theirs.
  static const _notificationId = 8291;

  bool _active = false;

  /// Whether the service is currently up.
  ///
  /// This is the answer to "can this take survive a background switch", which
  /// is what the recorder falls back on when it cannot.
  bool get isActive => _active;

  /// Registers the notification channel and the service options.
  ///
  /// Every option that would let the service outlive a take is off:
  /// [ForegroundTaskEventAction.nothing] because there is no task isolate to
  /// tick, and `autoRunOnBoot` / `autoRunOnMyPackageReplaced` /
  /// `allowAutoRestart` because a microphone notification resurrected after a
  /// reboot, an update, or a process kill would sit there with no recorder
  /// behind it. `allowWakeLock` stays on: that is the CPU lock keeping the
  /// encoder running with the screen off, not the screen lock.
  void configure() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'diary_recording',
        channelName: 'Diary recording',
        channelDescription:
            'Shown while a diary answer is being recorded, so recording '
            'continues if you leave the app.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
        allowAutoRestart: false,
      ),
    );
  }

  /// Starts the service, reporting whether it is up.
  ///
  /// Call only from the tap that begins or resumes a take. Android 12+ refuses
  /// to start a foreground service from the background, so starting it once
  /// the app is already away would be too late.
  ///
  /// `false` means the take is foreground-only.
  Future<bool> start() async {
    if (!Platform.isAndroid) return false;
    if (_active) return true;

    try {
      // A service left running by a previous recording would make startService
      // throw ServiceAlreadyStartedException; adopt it instead.
      if (await FlutterForegroundTask.isRunningService) {
        _active = true;
        return true;
      }

      final result = await FlutterForegroundTask.startService(
        serviceId: _notificationId,
        serviceTypes: const [ForegroundServiceTypes.microphone],
        notificationTitle: 'Recording your answer',
        notificationText: 'Tap to return to your diary.',
        // No callback on purpose: the recorder lives in the main isolate and
        // the service exists only to hold microphone access. Passing one would
        // spawn a second engine with nothing to run in it.
      );

      if (result is ServiceRequestFailure) {
        CrashlyticsService().recordError(
          result.error,
          StackTrace.current,
          reason: 'Recording foreground service failed to start',
        );
        return false;
      }

      _active = true;
      return true;
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Recording foreground service failed to start',
      );

      return false;
    }
  }

  /// Stops the service once capture ends.
  ///
  /// [isActive] is cleared before the call, not after: if the stop fails, the
  /// honest assumption is that background capture can no longer be relied on.
  /// Pausing a take that would have survived costs the participant a tap;
  /// trusting a service that is not there costs them the recording.
  Future<void> stop() async {
    if (!_active) return;
    _active = false;

    try {
      await FlutterForegroundTask.stopService();
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Recording foreground service failed to stop',
      );
    }
  }
}
