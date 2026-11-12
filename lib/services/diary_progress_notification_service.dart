import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:flutter/services.dart';

/// Drives the Android "Diary in progress" / "Next question waiting"
/// notification (android/.../features/diary), which alerts with the
/// channel's default sound. A no-op on other platforms.
///
/// Best-effort, like the other notification services: a failure here must
/// never get in the way of the diary itself.
class DiaryProgressNotificationService {
  /// [onAnswerNext] runs when "Next question waiting"'s Answer reopens the
  /// app, so the diary can move on to that question.
  DiaryProgressNotificationService({bool? isAndroid, this.onAnswerNext})
      : _isAndroid = isAndroid ?? Platform.isAndroid;

  static const _channel =
      MethodChannel('edu.emory.audio_diaries_flutter/diary_progress');

  final bool _isAndroid;
  final void Function()? onAnswerNext;

  /// Shows the diary as left on [questionNumber] (1-based) of
  /// [questionCount]: "Diary in progress", or "Next question waiting" when
  /// [currentAnswered] and another question follows. The native side ignores
  /// an out-of-range position.
  Future<void> show({
    required int questionNumber,
    required int questionCount,
    bool currentAnswered = false,
  }) {
    // Left in place by [hide]: Answer reopens the app, and the resume that
    // follows hides the notification, possibly before "answerNext" arrives.
    if (_isAndroid) _channel.setMethodCallHandler(_handleCall);

    return _invoke('show', <String, dynamic>{
      'questionNumber': questionNumber,
      'questionCount': questionCount,
      'currentAnswered': currentAnswered,
    });
  }

  /// Removes the notification. Safe to call when nothing is showing.
  Future<void> hide() => _invoke('hide', null);

  /// Removes the notification and stops listening for its action. Call when
  /// the diary closes.
  Future<void> dispose() {
    if (_isAndroid) _channel.setMethodCallHandler(null);
    return hide();
  }

  Future<void> _handleCall(MethodCall call) async {
    if (call.method == 'answerNext') onAnswerNext?.call();
  }

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
