import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/services.dart';

/// Bridges the diary "timer" question's countdown to an iOS Live Activity
/// (Lock Screen + Dynamic Island), via ios/Runner/AppDelegate.swift.
///
/// No-ops on non-iOS platforms and on iOS versions below 16.1 — Live
/// Activity display is best-effort UI and must never block or crash the
/// underlying timer flow.
class LiveActivityService {
  static const MethodChannel _channel = MethodChannel('diary/live_activity');

  static Future<void> start(DateTime endDate) => _invoke('start', {
        'endDateMillis': endDate.millisecondsSinceEpoch.toDouble(),
      });

  static Future<void> updateRunning(DateTime endDate) => _invoke('update', {
        'endDateMillis': endDate.millisecondsSinceEpoch.toDouble(),
        'isPaused': false,
      });

  static Future<void> updatePaused(Duration remaining) => _invoke('update', {
        'isPaused': true,
        'pausedRemainingMillis': remaining.inMilliseconds.toDouble(),
      });

  static Future<void> end() => _invoke('end');

  static Future<void> _invoke(String method,
      [Map<String, dynamic>? arguments]) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod(method, arguments);
    } catch (e) {
      dev.log('LiveActivityService.$method failed: $e', name: 'LiveActivityService');
    }
  }
}
