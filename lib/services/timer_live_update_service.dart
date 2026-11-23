import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/live_activity_channel.dart';
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
  static const _iosChannel = LiveActivityChannel.channel;

  static const _defaultTitle = 'Meditation timer';

  /// [isAndroid]/[isIOS] are injectable so the channel contracts can be
  /// exercised in tests, which run on the host platform. [enabled] gates
  /// both platforms at once — e.g. for a timer question configured not to
  /// show live updates.
  ///
  /// [onTogglePause] runs when the Android notification's Pause/Resume
  /// action or the iOS Live Activity's button is tapped. Android shows the
  /// action when [show] is called with `playbackControls: true`; iOS shows
  /// its button when [playbackControls] is set here.
  TimerLiveUpdateService({
    bool? isAndroid,
    bool? isIOS,
    this.enabled = true,
    this.questionNumber,
    this.questionCount,
    this.playbackControls = false,
    this.onTogglePause,
  })  : _isAndroid = isAndroid ?? Platform.isAndroid,
        _isIOS = isIOS ?? Platform.isIOS;

  final bool _isAndroid;
  final bool _isIOS;
  final bool enabled;
  final void Function()? onTogglePause;

  /// The question's place in the diary, shown as "Q5 of 8" on the iOS Live
  /// Activity. Both or neither.
  final int? questionNumber;
  final int? questionCount;

  /// Whether the timer can be paused, and so whether the iOS Live Activity
  /// shows its pause button.
  final bool playbackControls;

  /// Takes the Live Activity's pause button. Call once, before [start].
  void attach() {
    if (!_isIOS || !enabled || onTogglePause == null) return;
    LiveActivityChannel.on('timerTogglePause', _handleTogglePause);
  }

  void detach() {
    if (!_isIOS) return;
    LiveActivityChannel.off('timerTogglePause', _handleTogglePause);
  }

  Future<dynamic> _handleTogglePause() async {
    onTogglePause?.call();
    return null;
  }

  /// Starts the iOS Live Activity for a fresh countdown ending at [endDate].
  /// Skipped when the user has Live Activities disabled: requesting one then
  /// only fails natively. The later update/end calls are no-ops without one.
  Future<void> start(DateTime endDate, Duration totalDuration) async {
    if (!_isIOS || !enabled) return;
    if (!await LiveActivityChannel.areActivitiesEnabled()) return;
    await _invokeIOS('start', {
      'endDateMillis': endDate.millisecondsSinceEpoch.toDouble(),
      'totalDurationMillis': totalDuration.inMilliseconds.toDouble(),
      'canPause': playbackControls && onTogglePause != null,
      if (questionNumber != null && questionCount != null) ...{
        'questionNumber': questionNumber,
        'questionCount': questionCount,
      },
    });
  }

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
  ///
  /// [questionNumber]/[questionCount] render as "Q5 of 8". The Pause/Resume
  /// action is only added when [playbackControls] is true.
  Future<void> show({
    required Duration total,
    required Duration remaining,
    required bool isPaused,
    String title = _defaultTitle,
    int? questionNumber,
    int? questionCount,
    bool playbackControls = false,
  }) async {
    if (!_isAndroid || !enabled) return;
    if (total <= Duration.zero || remaining <= Duration.zero) return hide();

    _androidChannel.setMethodCallHandler(_handleAndroidCall);

    await _invokeAndroid('show', <String, dynamic>{
      'title': title,
      'totalSeconds': total.inSeconds,
      'remainingSeconds': remaining.inSeconds,
      'isPaused': isPaused,
      'questionNumber': questionNumber,
      'questionCount': questionCount,
      'playbackControls': playbackControls,
    });
  }

  /// Calls coming back from the native notification (its action buttons).
  Future<void> _handleAndroidCall(MethodCall call) async {
    if (call.method == 'togglePause') onTogglePause?.call();
  }

  /// Removes the Android notification and ends the iOS Live Activity. Safe
  /// to call when nothing is showing on either platform.
  Future<void> end() async {
    await hide();
    await _invokeIOS('end');
  }

  /// Removes the Android notification. Safe to call when nothing is showing.
  Future<void> hide() async {
    if (!_isAndroid || !enabled) return;
    _androidChannel.setMethodCallHandler(null);
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
    if (!_isIOS || !enabled) return;
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
