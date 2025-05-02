class PvtResult {
  final List<Duration> reactionTimes;
  final int lapseCount;
  final int falseStartCount;

  PvtResult({
    required this.reactionTimes,
    required this.lapseCount,
    required this.falseStartCount,
  });

  double get averageReactionTime {
    if (reactionTimes.isEmpty) return 0;
    final total = reactionTimes.fold<int>(0, (sum, t) => sum + t.inMilliseconds);
    return total / reactionTimes.length;
  }
}
