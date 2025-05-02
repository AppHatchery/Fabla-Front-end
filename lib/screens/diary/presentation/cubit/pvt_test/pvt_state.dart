part of 'pvt_cubit.dart';

class PvtState {
  final bool isStimulusVisible;
  final List<Duration> reactionTimes;
  final bool isFinished;
  final bool isTestStarted; 
  final int falseStartCount;

  PvtState({
    this.isStimulusVisible = false,
    this.reactionTimes = const [],
    this.isFinished = false,
    this.isTestStarted = false, 
    this.falseStartCount = 0,
  });

  PvtState copyWith({
    bool? isStimulusVisible,
    List<Duration>? reactionTimes,
    bool? isFinished,
    bool? isTestStarted,
    int? falseStartCount,
  }) {
    return PvtState(
      isStimulusVisible: isStimulusVisible ?? this.isStimulusVisible,
      reactionTimes: reactionTimes ?? this.reactionTimes,
      isFinished: isFinished ?? this.isFinished,
      isTestStarted: isTestStarted ?? this.isTestStarted,
      falseStartCount: falseStartCount ?? this.falseStartCount,
    );
  }
}
