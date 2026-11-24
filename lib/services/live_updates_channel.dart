import 'dart:developer' as dev;
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:flutter/services.dart';
import '../core/utils/statuses.dart';


/// The `live_updates` channel (LiveUpdatesChannel.kt).
class LiveUpdatesChannel {
  static const _channel =
      MethodChannel('edu.emory.audio_diaries_flutter/live_updates');

  /// Reads the app's notification and Live Updates settings. Null when the
  /// check fails, so the caller doesn't show a state it can't vouch for.
  static Future<LiveUpdatesStatus?> status() async {
    try {
      return switch (await _channel.invokeMethod<String>('status')) {
        'notificationsOff' => LiveUpdatesStatus.notificationsOff,
        'plain' => LiveUpdatesStatus.plain,
        'liveUpdates' => LiveUpdatesStatus.liveUpdates,
        'unsupported' => LiveUpdatesStatus.unsupported,
        _ => null,
      };
    } catch (e, stackTrace) {
      _report(e, stackTrace, 'status');
      return null;
    }
  }

  /// Opens the app's Live Updates switch in Android Settings.
  static Future<void> openLiveUpdateSettings() async {
    try {
      await _channel.invokeMethod<void>('openLiveUpdateSettings');
    } catch (e, stackTrace) {
      _report(e, stackTrace, 'openLiveUpdateSettings');
    }
  }

  /// Opens where notifications are turned back on: the blocked category's
  /// page when only a progress category is off, otherwise the app's
  /// notification settings.
  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod<void>('openNotificationSettings');
    } catch (e, stackTrace) {
      _report(e, stackTrace, 'openNotificationSettings');
    }
  }

  static void _report(Object error, StackTrace stackTrace, String method) {
    dev.log('LiveUpdatesChannel.$method failed: $error',
        name: 'LiveUpdatesChannel');
    CrashlyticsService().recordError(error, stackTrace,
        context: {'channel': _channel.name, 'method': method},
        reason: 'Android Live Updates call failed: $method');
  }
}
