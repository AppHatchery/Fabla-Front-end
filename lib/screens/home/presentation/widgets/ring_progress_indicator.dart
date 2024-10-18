import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:flutter/material.dart';

class RingProgressIndicator extends StatelessWidget {
  final double progress;
  final double size;
  final Color color;
  final Color backgroundColor;
  const RingProgressIndicator(
      {super.key,
      required this.progress,
      required this.size,
      required this.color,
      required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 0.5),
        duration: const Duration(milliseconds: 1000),
        builder: (context, value, _) => CircularProgressIndicator(
          value: progress,
          strokeWidth: 5,
          strokeCap: StrokeCap.round,
          backgroundColor: backgroundColor,
          color: color,
        ),
      ),
    );
  }
}

class GoalProgressIndicators extends StatelessWidget {
  final Map<StudyModel, List<DiaryModel>> goals;
  const GoalProgressIndicators({super.key, required this.goals});

  @override
  Widget build(BuildContext context) {
    double baseSize = 150;
    double spacing = 40;
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: goals.entries.toList().asMap().entries.map((entry) {
          int index = entry.key;
          final map = entry.value;
          Goal goal = map.key.goals;
          final diaries = map.value;
          final completed = diaries.fold(0,
              (previousValue, element) => previousValue + element.currentEntry);
          double progress = completed / goal.daily;
          double size = baseSize + (index * spacing);
          final color = getColorFromName(map.key.name);

          return RingProgressIndicator(
            progress: progress,
            size: size,
            color: color,
            backgroundColor: color.withOpacity(0.2),
          );
        }).toList(),
      ),
    );
  }
}
