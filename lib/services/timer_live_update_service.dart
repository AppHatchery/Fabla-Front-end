import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:flutter/services.dart';

/// Drives the platform-native "live" surfaces for the diary timer countdown:
/// the Android Live Update notification and the iOS Live Activity (Lock
/// Screen + Dynamic Island), the latter via ios/Runner/AppDelegate.swift.
///
/// Each side no-ops on the other platform, so callers don't need to guard by
/// platform themselves. Live-surface delivery is best-effort UI and must
/// never block or crash the underlying timer flow.
class TimerLiveUpdateService {
  static const _androidChannel =
      MethodChannel('edu.emory.audio_diaries_flutter/timer_live_update');
  static const _iosChannel = MethodChannel('diary/live_activity');

  static const _defaultTitle = 'Diary Timer';

  /// [isAndroid]/[isIOS] are injectable so the channel contracts can be
  /// exercised in tests, which run on the host platform.
  TimerLiveUpdateService({bool? isAndroid, bool? isIOS})
      : _isAndroid = isAndroid ?? Platform.isAndroid,
        _isIOS = isIOS ?? Platform.isIOS;

  final bool _isAndroid;
  final bool _isIOS;

  /// Starts the iOS Live Activity for a fresh countdown ending at [endDate].
  Future<void> start(DateTime endDate, Duration totalDuration) =>
      _invokeIOS('start', {
        'endDateMillis': endDate.millisecondsSinceEpoch.toDouble(),
        'totalDurationMillis': totalDuration.inMilliseconds.toDouble(),
      });

  /// Marks the iOS Live Activity as running (resumed) toward [endDate].
  ///
  /// Also the right call to force a repaint right when a countdown hits
  /// zero: passing the Live Activity's `staleDate` doesn't repaint it on its
  /// own once passed, so without a fresh update at that moment it stays
  /// showing its last-drawn state instead of flipping to "complete".
  Future<void> updateRunning(DateTime endDate) => _invokeIOS('update', {
        'endDateMillis': endDate.millisecondsSinceEpoch.toDouble(),
        'isPaused': false,
      });

  /// Marks the iOS Live Activity as paused with [remaining] time left.
  Future<void> updatePaused(Duration remaining) => _invokeIOS('update', {
        'isPaused': true,
        'pausedRemainingMillis': remaining.inMilliseconds.toDouble(),
      });

  /// Posts or refreshes the Android notification. Safe to call repeatedly.
  Future<void> show({
    required Duration total,
    required Duration remaining,
    required bool isPaused,
    String title = _defaultTitle,
  }) async {
    if (!_isAndroid) return;
    if (total <= Duration.zero || remaining <= Duration.zero) return hide();

    await _invokeAndroid('show', <String, dynamic>{
      'title': title,
      'totalSeconds': total.inSeconds,
      'remainingSeconds': remaining.inSeconds,
      'isPaused': isPaused,
    });
  }

  /// Removes the Android notification and ends the iOS Live Activity. Safe
  /// to call when nothing is showing on either platform.
  Future<void> end() async {
    await hide();
    await _invokeIOS('end');
  }

  /// Removes the Android notification. Safe to call when nothing is showing.
  Future<void> hide() async {
    if (!_isAndroid) return;
    await _invokeAndroid('hide', null);
  }

  /// Failing to post a notification must never take the timer down with it.
  Future<void> _invokeAndroid(
      String method, Map<String, dynamic>? arguments) async {
    try {
      await _androidChannel.invokeMethod<void>(method, arguments);
    } on PlatformException catch (e, stackTrace) {
      // Channel disabled or notifications blocked — nothing to recover.
      CrashlyticsService().recordError(e, stackTrace,
          context: {'channel': _androidChannel.name, 'method': method},
          reason: 'Android Live Update channel call failed: $method');
      dev.log('TimerLiveUpdateService.$method (Android) failed: $e',
          name: 'TimerLiveUpdateService');
    } on MissingPluginException catch (e, stackTrace) {
      // Engine detached (e.g. during teardown).
      CrashlyticsService().recordError(e, stackTrace,
          context: {'channel': _androidChannel.name, 'method': method},
          reason: 'Android Live Update channel unavailable: $method');
      dev.log('TimerLiveUpdateService.$method (Android) failed: $e',
          name: 'TimerLiveUpdateService');
    }
  }

  Future<void> _invokeIOS(String method,
      [Map<String, dynamic>? arguments]) async {
    if (!_isIOS) return;
    try {
      await _iosChannel.invokeMethod(method, arguments);
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          context: {'channel': _iosChannel.name, 'method': method},
          reason: 'iOS Live Activity channel call failed: $method');
      dev.log('TimerLiveUpdateService.$method (iOS) failed: $e',
          name: 'TimerLiveUpdateService');
    }
  }
}
