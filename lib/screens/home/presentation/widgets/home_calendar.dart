import 'package:flutter/material.dart';

import '../../../../core/utils/statuses.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../../../diary/domain/repository/diary_repository.dart';

class StreakCalendar extends StatefulWidget {
  const StreakCalendar({super.key});

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  final List<Widget> days = [];
  late String heading;
  late String message;

  @override
  Widget build(BuildContext context) {
    prepare();
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      decoration: BoxDecoration(
          color: CustomColors.fillWhite,
          border: Border.all(
            color: CustomColors.productBorderNormal,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: CustomColors.yellowDark,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                      child: Container(
                    alignment: Alignment.centerLeft,
                    child: const Icon(Icons.ads_click_rounded,
                        size: 32, color: CustomColors.fillWhite),
                  )),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          heading,
                          style: CustomTypography()
                              .titleLarge(color: CustomColors.fillWhite),
                        ),
                        Text(
                          message,
                          style: CustomTypography()
                              .bodyMedium(color: CustomColors.fillWhite),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: days,
            ),
          ),
        ],
      ),
    );
  }

  Widget dayOfTheWeek(String day, String date, bool isToday, bool? isComplete) {
    late Color color;
    late Color foreground;

    if (isToday) {
      color = CustomColors.productNormalActive;
      foreground = CustomColors.textWhite;
    } else if (isComplete == null) {
      color = Colors.transparent;
      foreground = CustomColors.textTertiaryContent;
    } else if (isComplete) {
      color = const Color(0xFF1FBE4C);
      foreground = CustomColors.textWhite;
    } else {
      color = const Color(0xFFB4D5FF).withOpacity(0.5);
      foreground = CustomColors.textTertiaryContent;
    }

    return Column(
      children: [
        Text(
          day.toString(),
          style: CustomTypography().titleSmall(
            color: CustomColors.textTertiaryContent,
          ),
        ),
        Container(
            height: 35,
            width: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Text(
              date,
              style: CustomTypography().bodyLarge(
                color: foreground,
              ),
              textAlign: TextAlign.center,
            )),
      ],
    );
  }

  void prepare() async {
    days.clear();
    final now = DateTime.now();
    final today = now.weekday;
    DateTime sunday = now.subtract(Duration(days: now.weekday - 1));
    DateTime saturday = sunday.add(const Duration(days: 6));

    //Get all the diaries
    final diaries = DiaryRepository().getAllDiaries();
    final thisWeek = diaries
        .where((element) =>
            element.start.isAfter(sunday.subtract(const Duration(days: 1))) &&
            element.start.isBefore(saturday.add(const Duration(days: 1))))
        .toList();

    if (thisWeek.isEmpty || diaries.first.start.isAfter(now)) {
      final difference = diaries.first.start.difference(sunday).inDays;
      heading = "$difference days left for your first diary";
      message = "See you later!";
    } else {
      final left = thisWeek
          .where((element) =>
              element.status != DiaryStatus.submitted &&
              element.start.isAfter(now.subtract(const Duration(days: 1))))
          .toList();
      heading = "${left.length} diaries left for this study";
      message = "Time to take diaries!";
    }

    List<DateTime> _days = [];

    for (int i = 0; i < 7; i++) {
      _days.add(sunday.add(Duration(days: i)));
    }

    for (final d in _days) {
      final isToday = d.weekday == today;
      final todayDiaries =
          thisWeek.where((element) => element.start.day == d.day).toList();
      final diary = todayDiaries.firstOrNull;
      final isComplete =
          diary == null ? null : diary.status == DiaryStatus.submitted;

      days.add(dayOfTheWeek(_dayAbbreviations[d.weekday]!, d.day.toString(),
          isToday, isComplete));
    }
  }

  // Define a map of day abbreviations.
  final Map<int, String> _dayAbbreviations = {
    1: "S",
    2: "M",
    3: "T",
    4: "W",
    5: "T",
    6: "F",
    7: "S",
  };
}
