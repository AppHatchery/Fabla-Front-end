import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/live_activity_channel.dart';

/// Shows an open diary on the iOS Lock Screen and Dynamic Island ("Diary in
/// progress", Q3 of 8), via ios/Runner/AppDelegate.swift, so a participant
/// who leaves part-way can come back to it.
///
/// Started while the diary is on screen (iOS only lets an app start a Live
/// Activity from the foreground), moved along as the participant pages, and
/// ended when the diary is finished or closed. iOS hides it in the Dynamic
/// Island while Fabla itself is open. A no-op off iOS, and best-effort like
/// [TimerLiveUpdateService]: it must never get in the way of the diary.
class DiaryProgressLiveActivityService {
  static const _channel = LiveActivityChannel.channel;

  DiaryProgressLiveActivityService(
      {required this.questionCount, this.closesAt, bool? isIOS})
      : _isIOS = isIOS ?? Platform.isIOS;

  final int questionCount;

  /// When the diary closes. In its last 15 minutes the activity turns to
  /// "Diary closes soon" and counts down to it, on its own (see AppDelegate).
  final DateTime? closesAt;
  final bool _isIOS;

  bool _active = false;
  int? _lastQuestion;
  bool? _lastWaiting;

  /// Starts the activity on [questionNumber] (1-based), or moves it there.
  ///
  /// [waiting]: the question is answered and the next one is waiting, so
  /// the activity points at question [questionNumber] + 1 instead.
  Future<void> show(int questionNumber, {bool waiting = false}) async {
    if (!_isIOS || questionCount <= 0) return;
    if (_active &&
        _lastQuestion == questionNumber &&
        _lastWaiting == waiting) {
      return;
    }
    _lastQuestion = questionNumber;
    _lastWaiting = waiting;
    final args = {
      'questionNumber': waiting ? questionNumber + 1 : questionNumber,
      'waiting': waiting,
    };

    if (_active) {
      await _invoke('diaryUpdate', args);
      return;
    }
    _active = true;
    if (!await _isEnabled()) return;
    await _invoke('diaryStart', {
      ...args,
      'questionCount': questionCount,
      if (closesAt != null)
        'closesAtMillis': closesAt!.millisecondsSinceEpoch.toDouble(),
    });
  }

  /// Ends the activity. Safe to call when nothing is showing.
  Future<void> end() async {
    if (!_isIOS || !_active) return;
    _active = false;
    _lastQuestion = null;
    _lastWaiting = null;
    await _invoke('diaryEnd');
  }

  Future<bool> _isEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('checkLiveActivityPermission') ??
          false;
    } catch (e) {
      dev.log('DiaryProgressLiveActivityService permission check failed: $e',
          name: 'DiaryProgressLiveActivityService');
      return false;
    }
  }

  Future<void> _invoke(String method, [Map<String, dynamic>? arguments]) async {
    try {
      await _channel.invokeMethod(method, arguments);
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          context: {'channel': _channel.name, 'method': method},
          reason: 'iOS diary progress Live Activity call failed: $method');
      dev.log('DiaryProgressLiveActivityService.$method failed: $e',
          name: 'DiaryProgressLiveActivityService');
    }
  }
}
