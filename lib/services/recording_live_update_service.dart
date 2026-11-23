import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:flutter/services.dart';

/// What the recording notification shows. Sent to the native side by [name].
enum RecordingLiveUpdatePhase {
  /// Capturing: Pause action, ticking elapsed time.
  recording,

  /// Paused by the participant: Resume action.
  paused,

  /// Paused because a call (or another app) took the microphone: Resume.
  pausedByCall,

  /// Stopped with a take waiting to be saved: Save action. Not a Live Update.
  readyToSave,

  /// A resume was refused because the microphone is busy; the take is kept,
  /// still paused. Open action. Alerts.
  couldNotResume,

  /// The take was saved. No action.
  saved,

  /// The take stopped with nothing recorded. Record again action, which
  /// reopens the app. Alerts.
  recordingStopped,
}

/// Drives the Android Live Update notification for an in-progress diary
/// recording (android/.../RecordingLiveUpdate.kt). A no-op on other
/// platforms.
///
/// State is pushed on transitions only: the native side ticks the elapsed
/// time and progress bar off the wall clock. Like the timer's live update,
/// delivery is best-effort and must never break the recording itself.
class RecordingLiveUpdateService {
  static const _channel =
      MethodChannel('edu.emory.audio_diaries_flutter/recording_live_update');

  static const _defaultTitle = 'Recording';

  /// Callbacks for the notification's actions: [onPause] and [onSave] run
  /// from the shade, [onResume] and [onRecordAgain] also reopen the app.
  RecordingLiveUpdateService({
    bool? isAndroid,
    this.onPause,
    this.onResume,
    this.onSave,
    this.onRecordAgain,
  }) : _isAndroid = isAndroid ?? Platform.isAndroid;

  final bool _isAndroid;
  final void Function()? onPause;
  final void Function()? onResume;
  final void Function()? onSave;
  final void Function()? onRecordAgain;

  /// Posts or refreshes the notification. Safe to call repeatedly.
  ///
  /// [limit] drives the "up to 5:00" text and the four-part progress bar;
  /// without one neither is shown.
  Future<void> show({
    required Duration elapsed,
    required RecordingLiveUpdatePhase phase,
    Duration? limit,
    int? questionNumber,
    int? questionCount,
    String title = _defaultTitle,
  }) async {
    if (!_isAndroid) return;

    _channel.setMethodCallHandler(_handleCall);

    await _invoke('show', <String, dynamic>{
      'title': title,
      'elapsedSeconds': elapsed.inSeconds,
      'limitSeconds': limit?.inSeconds ?? 0,
      'phase': phase.name,
      'questionNumber': questionNumber,
      'questionCount': questionCount,
    });
  }

  /// Removes the notification. Safe to call when nothing is showing.
  Future<void> hide() async {
    if (!_isAndroid) return;
    _channel.setMethodCallHandler(null);
    await _invoke('hide', null);
  }

  Future<void> _handleCall(MethodCall call) async {
    switch (call.method) {
      case 'pause':
        onPause?.call();
      case 'resume':
        onResume?.call();
      case 'save':
        onSave?.call();
      case 'recordAgain':
        onRecordAgain?.call();
    }
  }

  Future<void> _invoke(String method, Map<String, dynamic>? arguments) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          context: {'channel': _channel.name, 'method': method},
          reason: 'Recording Live Update channel call failed: $method');
      dev.log('RecordingLiveUpdateService.$method failed: $e',
          name: 'RecordingLiveUpdateService');
    }
  }
}
