import 'dart:async';

import 'package:flutter/widgets.dart';

import '../usecases/recording_answer.dart';
import 'statuses.dart';
import '../../services/crashlytics_service.dart';
import '../../screens/diary/data/prompt.dart';

mixin RecordingAnswerGate<T extends StatefulWidget> on State<T> {
  void discardRecording(String path);

  bool get gatedPromptIsSingleAnswer;

  Future<void> reevaluateAnswers();

  /// The single verdict on this prompt's recordings, shared with the card so
  /// the record button and the gate cannot disagree.
  late final RecordingAnswerChecker answers = RecordingAnswerChecker(
    discard: discardRecording,
    singleAnswer: gatedPromptIsSingleAnswer,
    onError: (error, stackTrace, reason) => CrashlyticsService().recordError(
      error,
      stackTrace,
      reason: reason,
    ),
  );

  int _responseCheckToken = 0;

  bool _answersUnchecked = false;

  bool get answersCouldNotBeChecked => _answersUnchecked;

  void onPlaybackResolved(String path, AudioStatus status) {
    if (!mounted || !answers.report(path, status)) return;

    _answersChanged();
  }

  void onDismissRecording(String path) {
    if (!mounted) return;

    answers.dismiss(path);

    _answersChanged();
  }

  void _answersChanged() {
    setState(() {});
    unawaited(_reevaluateGuarded());
  }

  Future<void> _reevaluateGuarded() async {
    try {
      await reevaluateAnswers();
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Re-evaluating the prompt\'s answers failed',
      );
    }
  }

  Future<UsableAnswerCount?> countUsableAnswers(PromptModel prompt) async {
    final token = ++_responseCheckToken;

    final count = await answers.countUsable(prompt.answer?.recordings ?? []);

    if (!mounted || token != _responseCheckToken) return null;

    setState(() => _answersUnchecked = !count.checked);

    return count;
  }
}
