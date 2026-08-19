import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Drives the Android Live Update notification for the diary timer.
///
/// The native side owns the countdown rendering (platform chronometer off a
/// wall-clock end time), so this only needs to push whole-state snapshots on
/// transitions — not once per second.
///
/// No-op on iOS, which uses its own Live Activity.
class TimerLiveUpdateService {
  static const _channel =
      MethodChannel('edu.emory.audio_diaries_flutter/timer_live_update');

  static const _defaultTitle = 'Diary Timer';

  const TimerLiveUpdateService();

  /// Posts or refreshes the notification. Safe to call repeatedly.
  Future<void> show({
    required Duration total,
    required Duration remaining,
    required bool isPaused,
    String title = _defaultTitle,
  }) async {
    if (!Platform.isAndroid) return;
    if (total <= Duration.zero || remaining <= Duration.zero) return hide();

    await _invoke('show', <String, dynamic>{
      'title': title,
      'totalSeconds': total.inSeconds,
      'remainingSeconds': remaining.inSeconds,
      'isPaused': isPaused,
    });
  }

  /// Removes the notification. Safe to call when nothing is showing.
  Future<void> hide() async {
    if (!Platform.isAndroid) return;
    await _invoke('hide', null);
  }

  /// Failing to post a notification must never take the timer down with it.
  Future<void> _invoke(String method, Map<String, dynamic>? arguments) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException {
      // Channel disabled or notifications blocked — nothing to recover.
    } on MissingPluginException {
      // Engine detached (e.g. during teardown).
    }
  }
}
