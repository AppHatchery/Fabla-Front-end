import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:flutter/services.dart';

/// Drives the Android "Diary in progress" notification
/// (android/.../features/diary), which alerts with the channel's default
/// sound. A no-op on other platforms.
///
/// Best-effort, like the other notification services: a failure here must
/// never get in the way of the diary itself.
class DiaryProgressNotificationService {
  DiaryProgressNotificationService({bool? isAndroid})
      : _isAndroid = isAndroid ?? Platform.isAndroid;

  static const _channel =
      MethodChannel('edu.emory.audio_diaries_flutter/diary_progress');

  final bool _isAndroid;

  /// Shows the diary as left on [questionNumber] (1-based) of
  /// [questionCount]. The native side ignores an out-of-range position.
  Future<void> show({
    required int questionNumber,
    required int questionCount,
  }) =>
      _invoke('show', <String, dynamic>{
        'questionNumber': questionNumber,
        'questionCount': questionCount,
      });

  /// Removes the notification. Safe to call when nothing is showing.
  Future<void> hide() => _invoke('hide', null);

  Future<void> _invoke(String method, Map<String, dynamic>? arguments) async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          context: {'channel': _channel.name, 'method': method},
          reason: 'Diary progress notification call failed: $method');
      dev.log('DiaryProgressNotificationService.$method failed: $e',
          name: 'DiaryProgressNotificationService');
    }
  }
}
