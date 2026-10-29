import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/services/audio_recording_service.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:flutter/services.dart';

/// Mirrors one diary answer's take onto the iOS recording Live Activity (Lock
/// Screen + Dynamic Island), via ios/Runner/AppDelegate.swift.
///
/// Follows [AudioRecordingState]: starts with the take, updates when it
/// pauses or resumes, and stays up as "Ready to save" once it stops with a
/// take to keep. It ends when the take is saved or dropped. The activity's
/// own buttons come back as [onTogglePause] and [onSave]. A no-op off iOS, and best-effort like
/// [TimerLiveUpdateService]: it must never block or crash the recorder.
class RecordingLiveActivityService {
  static const _channel = MethodChannel('diary/live_activity');

  RecordingLiveActivityService({
    required this.onTogglePause,
    required this.onSave,
    this.limit,
    this.hardLimit,
    this.questionNumber,
    this.questionCount,
    bool? isIOS,
  }) : _isIOS = isIOS ?? Platform.isIOS;

  /// Runs when the participant taps pause or resume on the Live Activity.
  final Future<void> Function() onTogglePause;

  /// Runs when the participant taps save on a stopped take.
  final Future<void> Function() onSave;

  /// The length shown on the activity: the suggestion, else the limit.
  final Duration? limit;

  /// The question's real limit, where the recorder stops. Only this turns on
  /// the "One minute left" state; without one it never shows.
  final Duration? hardLimit;

  /// The question's place in the diary, shown as "Q3 of 8". Both or neither.
  final int? questionNumber;
  final int? questionCount;

  final bool _isIOS;

  bool _active = false;
  bool? _lastPaused;
  bool? _lastInterrupted;
  bool? _lastReady;

  /// While a save runs the take clears before the outcome is known, so the
  /// activity holds on rather than ending; [saved] or [releaseHold] follows.
  bool _holding = false;

  /// Ended as "Saved": nothing after that may end it early.
  bool _finished = false;

  /// The take's length as last shown, for the "Saved" card.
  Duration _lastElapsed = Duration.zero;

  /// The last state [sync] saw, read back after the activity's button runs.
  AudioRecordingState? _lastState;

  /// Takes the channel's incoming calls. Call once, before the first take.
  void attach() {
    if (!_isIOS) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'recordingSave') {
        await onSave();
        return null;
      }
      if (call.method != 'recordingTogglePause') return null;
      await onTogglePause();
      // The microphone could not be reclaimed. From the background that is
      // iOS refusing a session a call took ('!int'); the native side then
      // asks to continue in the foreground, where resuming is allowed.
      return {'needsForeground': _lastState?.microphoneUnavailable ?? false};
    });
  }

  /// Brings the activity in line with [state]. Safe to call on every change:
  /// elapsed time ticks natively, so only a status change reaches iOS.
  Future<void> sync(AudioRecordingState state) async {
    if (!_isIOS) return;
    _lastState = state;
    // Stopped with a take is waiting on the save button, so it stays up.
    final ready = state.status == AudioRecordingStatus.stopped && state.hasTake;
    final live = state.isRecording || state.isPaused || ready;

    if (!live) {
      if (_active && !_holding) await end();
      return;
    }
    _lastElapsed = state.elapsed;
    if (_active &&
        _lastPaused == state.isPaused &&
        _lastInterrupted == state.isInterrupted &&
        _lastReady == ready) {
      return;
    }

    final args = <String, dynamic>{
      'elapsedMillis': state.elapsed.inMilliseconds.toDouble(),
      // Ready shows frozen, like a pause.
      'isPaused': state.isPaused || ready,
      'isReady': ready,
      // Paused by the audio system, most often a call, not by the participant.
      'isInterrupted': state.isPaused && state.isInterrupted,
    };
    _lastPaused = state.isPaused;
    _lastInterrupted = state.isInterrupted;
    _lastReady = ready;

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
      if (hardLimit != null && hardLimit! > Duration.zero)
        'hardLimitMillis': hardLimit!.inMilliseconds.toDouble(),
      if (questionNumber != null && questionCount != null) ...{
        'questionNumber': questionNumber,
        'questionCount': questionCount,
      },
    });
  }

  /// Keeps the activity up through a save. See [_holding].
  void holdForSave() => _holding = true;

  /// The save didn't go through: back to following the take.
  Future<void> releaseHold() async {
    _holding = false;
    final state = _lastState;
    if (state != null) await sync(state);
  }

  /// Ends the activity on its "Saved" card, which the system leaves up a
  /// few seconds before dismissing.
  Future<void> saved() async {
    _holding = false;
    if (!_active) return;
    _active = false;
    _finished = true;
    await _invoke('recordingSaved', {
      'elapsedMillis': _lastElapsed.inMilliseconds.toDouble(),
    });
  }

  /// Ends the activity and stops taking the channel's calls.
  Future<void> end() async {
    if (_finished) return;
    _active = false;
    _lastPaused = null;
    _lastInterrupted = null;
    _lastReady = null;
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
