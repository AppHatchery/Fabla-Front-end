import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyGoalPopup extends StatefulWidget {
  final List<StudyModel> studies;
  final List<DiaryModel> diaries;

  const WeeklyGoalPopup(
      {super.key, required this.studies, required this.diaries});

  @override
  State<WeeklyGoalPopup> createState() => _WeeklyGoalPopupState();
}

class _WeeklyGoalPopupState extends State<WeeklyGoalPopup>
    with SingleTickerProviderStateMixin {
  String thisWeek = "";

  Map<StudyModel, List<DiaryModel>> data = {};

  @override
  void initState() {
    thisWeek = getThisWeek();
    // create map of study to diaries
    for (var study in widget.studies) {
      final diaries =
          widget.diaries.where((diary) => diary.studyID == study.studyId);
      data[study] = diaries.toList();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double totalWidth = width - 32;

    return Container(
      width: width,
      color: CustomColors.fillWhite,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //THIS WEEK
            Wrap(
              children: [
                Text(
                  thisWeek,
                  style: CustomTypography().caption(),
                ),
              ],
            ),

            const SizedBox(
              height: 6,
            ),
            Column(
                children: data.entries.isNotEmpty
                    ? data.entries.toList().asMap().entries.map((e) {
                        final value = e.value;
                        return goalWidget(
                            width,
                            totalWidth,
                            value.key,
                            value.value,
                            e.value.key.color ?? CustomColors.productNormal);
                      }).toList()
                    : [
                        Text("No entries needed this week",
                            style: CustomTypography().titleMedium())
                      ]),
          ],
        ),
      ),
    );
  }

  getThisWeek() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final DateFormat formatter = DateFormat("EEEE, MMM d");

    return "${formatter.format(monday)} - ${formatter.format(sunday)}";
  }

  Widget goalWidget(double width, double totalWidth, StudyModel study,
      List<DiaryModel> diaries, Color color) {
    final lowerGoal = (0.7 * study.goals.weekly).round();
    final lowerValue = (lowerGoal / study.goals.weekly) * totalWidth;

    final currentEntries =
        diaries.where((diary) => diary.status == DiaryStatus.submitted).length;
    final progress = (currentEntries / study.goals.weekly) * totalWidth;
    final progressWidth = (progress > totalWidth) ? totalWidth : progress;

    return Column(
      children: [
        //TAG
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              Icons.restart_alt_outlined,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              study.name,
              style: CustomTypography().bodyMedium(),
            )
          ],
        ),
        const SizedBox(
          height: 6,
        ),
        //INTRODUCTION
        Wrap(
          children: [
            SizedBox(
              width: width - 50,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  "Submit at least $lowerGoal ${study.goals.weekly > 1 ? "entries" : "entry"} this week to complete your goal.",
                  style: CustomTypography().caption(),
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 6,
        ),
        //PROGRESS
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: totalWidth,
              height: 45,
              child: Stack(
                children: [
                  //PROGRESS BAR BACKGROUND
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: totalWidth,
                      height: 6,
                      constraints: const BoxConstraints(maxHeight: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                  ),
                  //PROGRESS BAR
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: progressWidth,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                  ),
                  //PROGRESS INDICATOR
                  Positioned(
                    left: (progressWidth),
                    top: 0,
                    bottom: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20),
                            // Adjust padding instead of using SizedBox
                            child: Opacity(
                              opacity: lowerValue == progressWidth ||
                                      study.goals.weekly >= progressWidth
                                  ? 0
                                  : 1,
                              // Hide the progress indicator when it reaches the lower goal
                              child: Text(
                                "$currentEntries",
                                style: CustomTypography().caption(),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  //LOWER GOAL
                  Positioned(
                    left: lowerValue,
                    top: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(CupertinoIcons.flag_fill, color: color, size: 17),
                        const SizedBox(
                          height: 5,
                        ),
                        Flexible(
                          child: Text(
                            "$lowerGoal",
                            style: CustomTypography().caption(),
                          ),
                        )
                      ],
                    ),
                  ),
                  //HIGHER GOAL
                  Positioned(
                    // left: 70 * value - 10,
                    left: (width - 52),
                    top: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            color: color, size: 20),
                        Flexible(
                          child: Text(
                            "${study.goals.weekly}",
                            style: CustomTypography().caption(),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
