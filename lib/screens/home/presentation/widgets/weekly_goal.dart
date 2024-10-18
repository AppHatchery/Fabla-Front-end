import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WeeklyGoalWidget extends StatefulWidget {
  final int currentEntries;
  final int weeklyGoal;
  final bool isExpanded;
  final StudyModel? study;
  const WeeklyGoalWidget(
      {super.key,
      required this.isExpanded,
      required this.currentEntries,
      required this.weeklyGoal,
      required this.study});

  @override
  State<WeeklyGoalWidget> createState() => _WeeklyGoalWidgetState();
}

class _WeeklyGoalWidgetState extends State<WeeklyGoalWidget> {
  final value = 0.0;
  @override
  Widget build(BuildContext context) {
    double width = 70;
    //calculate the progress bar width
    final currentValue = widget.currentEntries;
    int weeklyGoal = widget.weeklyGoal;
    double progressValue = (currentValue / weeklyGoal) * width;

    double progressBarWidth = progressValue.isNaN
        ? 0
        : (progressValue > width)
            ? width
            : progressValue;
    //calculate the lower goal width/value
    int lowerValue = (0.7 * weeklyGoal).round();
    double lowerGoal = (lowerValue / weeklyGoal) * width;
    final color = widget.study != null ? getColorFromName(widget.study!.name) : CustomColors.productNormal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Weekly Goal", style: CustomTypography().bodyLarge()),
            const SizedBox(width: 6),
            GestureDetector(
              child: Icon(
                widget.isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: CustomColors.textTertiaryContent,
                size: 20,
              ),
            )
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: width,
              height: 20,
              child: Stack(
                children: [
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 70,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                  ),
                  // current progress
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: progressBarWidth,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                  ),
                  //lower goal
                  Positioned(
                    // left: 70 * value - 10,
                    left: lowerGoal,
                    top: 2,
                    child: Icon(CupertinoIcons.flag_fill,
                        color: color, size: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                "$currentValue/$weeklyGoal",
                style: CustomTypography()
                    .caption(color: color),
              ),
            )
          ],
        ),
      ],
    );
  }
}
