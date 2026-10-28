import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:audio_diaries_flutter/services/audio_recording_service.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:flutter/services.dart';

/// Mirrors one diary answer's take onto the iOS recording Live Activity (Lock
/// Screen + Dynamic Island), via ios/Runner/AppDelegate.swift.
///
/// Follows [AudioRecordingState]: starts with the take, updates when it
/// pauses or resumes, ends when the take stops. The activity's own button
/// comes back as [onTogglePause]. A no-op off iOS, and best-effort like
/// [TimerLiveUpdateService]: it must never block or crash the recorder.
class RecordingLiveActivityService {
  static const _channel = MethodChannel('diary/live_activity');

  RecordingLiveActivityService({
    required this.onTogglePause,
    this.limit,
    this.questionNumber,
    this.questionCount,
    bool? isIOS,
  }) : _isIOS = isIOS ?? Platform.isIOS;

  /// Runs when the participant taps pause or resume on the Live Activity.
  final Future<void> Function() onTogglePause;

  final Duration? limit;

  /// The question's place in the diary, shown as "Q3 of 8". Both or neither.
  final int? questionNumber;
  final int? questionCount;

  final bool _isIOS;

  bool _active = false;
  bool? _lastPaused;

  /// Takes the channel's incoming calls. Call once, before the first take.
  void attach() {
    if (!_isIOS) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'recordingTogglePause') await onTogglePause();
    });
  }

  /// Brings the activity in line with [state]. Safe to call on every change:
  /// elapsed time ticks natively, so only a status change reaches iOS.
  Future<void> sync(AudioRecordingState state) async {
    if (!_isIOS) return;
    final live = state.isRecording || state.isPaused;

    if (!live) {
      if (_active) await end();
      return;
    }
    if (_active && _lastPaused == state.isPaused) return;

    final args = <String, dynamic>{
      'elapsedMillis': state.elapsed.inMilliseconds.toDouble(),
      'isPaused': state.isPaused,
    };
    _lastPaused = state.isPaused;

    if (_active) {
      await _invoke('recordingUpdate', args);
      return;
    }
    _active = true;
    if (!await _isEnabled()) return;
    await _invoke('recordingStart', {
      ...args,
      // A zero limit means none, as it does to the recorder.
      if (limit != null && limit! > Duration.zero)
        'limitMillis': limit!.inMilliseconds.toDouble(),
      if (questionNumber != null && questionCount != null) ...{
        'questionNumber': questionNumber,
        'questionCount': questionCount,
      },
    });
  }

  /// Ends the activity and stops taking the channel's calls.
  Future<void> end() async {
    _active = false;
    _lastPaused = null;
    await _invoke('recordingEnd');
  }

  void detach() {
    if (!_isIOS) return;
    _channel.setMethodCallHandler(null);
  }

  Future<bool> _isEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('checkLiveActivityPermission') ??
          false;
    } catch (e) {
      dev.log('RecordingLiveActivityService permission check failed: $e',
          name: 'RecordingLiveActivityService');
      return false;
    }
  }

  Future<void> _invoke(String method, [Map<String, dynamic>? arguments]) async {
    if (!_isIOS) return;
    try {
      await _channel.invokeMethod(method, arguments);
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          context: {'channel': _channel.name, 'method': method},
          reason: 'iOS recording Live Activity call failed: $method');
      dev.log('RecordingLiveActivityService.$method failed: $e',
          name: 'RecordingLiveActivityService');
    }
  }
}
