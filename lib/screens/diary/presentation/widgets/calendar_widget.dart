import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

final now = DateTime.now();

class CompleteCalendarWidget extends StatefulWidget {
  final List<DiaryModel> diaries;
  final int dailyGoal;
  final int weeklyGoal;
  const CompleteCalendarWidget(
      {super.key,
      required this.diaries,
      required this.dailyGoal,
      required this.weeklyGoal});

  @override
  State<CompleteCalendarWidget> createState() => _CompleteCalendarWidgetState();
}

class _CompleteCalendarWidgetState extends State<CompleteCalendarWidget> {
  late int currentEntryCount;
  final List<Widget> days = [];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    prepare();
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: CustomColors.fillWhite,
        boxShadow: const [
          BoxShadow(
            color: CustomColors.productBorderNormal,
            blurRadius: 5,
            offset: Offset(0, 0),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: days,
          ),
          const Divider(
            color: CustomColors.productBorderNormal,
          ),
          const SizedBox(
            height: 12,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              currentEntryCount == widget.dailyGoal
                  ? "You achieved your daily goal. Great work!"
                  : "You've got ${widget.dailyGoal - currentEntryCount} entry left today",
              textAlign: TextAlign.center,
              style: CustomTypography()
                  .body(color: CustomColors.textSecondaryContent),
            ),
          )
        ],
      ),
    );
  }

  Widget dayOfTheWeek(String dayAbbreviation, bool isToday, double percentage,
      bool showProgress, bool isAfter) {
    return Opacity(
      opacity: showProgress ? 1 : 0,
      child: Column(
        children: [
          Text(
            dayAbbreviation,
            style: CustomTypography().bodyMedium(
              color: isToday ? Colors.black : CustomColors.textTertiaryContent,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (isAfter)
            DottedBorder(
              borderType: BorderType.Circle,
              strokeWidth: 2,
              color: CustomColors.productBorderNormal,
              dashPattern: const [6],
              child: const SizedBox(height: 30, width: 30),
            )
          else
            CircularProgressIndicator(
              strokeWidth: 2,
              value: percentage,
              backgroundColor: CustomColors.productBorderNormal,
              color: CustomColors.productNormal,
            ),
        ],
      ),
    );
  }

  void prepare() async {
    days.clear();
    final today = now.weekday;
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));

    final List<DateTime> _days =
        List.generate(7, (index) => monday.add(Duration(days: index)));

    for (final d in _days) {
      final isToday = d.weekday == today;
      final diary = widget.diaries
          .where(
            (element) => element.start.day == d.day,
          )
          .firstOrNull;
      final max = widget.dailyGoal;
      final current = diary != null
          ? diary.status == DiaryStatus.submitted
              ? diary.entries
              : diary.currentEntry
          : 0;
      final isAfter = d.isAfter(now);

      final percentage = current / max;

      if (diary?.start.day == now.day && mounted) {
        setState(() {
          currentEntryCount = current;
        });
      }

      final showProgress = (diary != null && diary.currentEntry > 0) || (diary != null && isAfter);

      days.add(dayOfTheWeek(_dayAbbreviations[d.weekday]!, isToday, percentage,
          showProgress, isAfter));
    }
  }

  final Map<int, String> _dayAbbreviations = {
    1: "M",
    2: "T",
    3: "W",
    4: "T",
    5: "F",
    6: "S",
    7: "S",
  };
}
