import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/protocol.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TodayGoalWidget extends StatefulWidget {
  final int dailyGoal;
  final Protocol protocol;
  final DiaryModel diary;
  const TodayGoalWidget(
      {super.key,
      required this.dailyGoal,
      required this.protocol,
      required this.diary});

  @override
  State<TodayGoalWidget> createState() => _TodayGoalWidgetState();
}

class _TodayGoalWidgetState extends State<TodayGoalWidget> {
  @override
  Widget build(BuildContext context) {
    final entry = widget.diary.status == DiaryStatus.submitted
        ? widget.diary.entries
        : widget.diary.currentEntry;

    //calculate the daily goal progress bar width
    final dailyValue = ((entry) / widget.protocol.dailyGoal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Goal", style: CustomTypography().titleLarge()),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.center,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: SizedBox(
                    height: 120,
                    width: 120,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 0.5),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, value, _) => CircularProgressIndicator(
                        strokeWidth: 5,
                        value: dailyValue,
                        backgroundColor: CustomColors.productLightBackground,
                        color: CustomColors.productNormal,
                      ),
                    )),
              ),
              Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 5,
                        height: 10,
                        color: Colors.white,
                      ),
                    ],
                  )),
              Container(
                height: 120,
                width: 120,
                alignment: Alignment.center,
                padding: const EdgeInsets.only(top: 5),
                child: Image.asset(
                  "assets/images/today_goal_avatar.png",
                  width: 80,
                  height: 80,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restart_alt_outlined,
              color: CustomColors.productNormal,
              size: 20,
            ),
            const SizedBox(width: 6),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                "Repeatable Entries: $entry/${widget.protocol.dailyGoal}",
                style: CustomTypography().bodyMedium(),
              ),
            ),
          ],
        )
      ],
    );
  }
}
