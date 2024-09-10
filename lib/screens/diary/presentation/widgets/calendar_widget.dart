import 'package:audio_diaries_flutter/core/utils/dummy_data.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class CompleteCalendarWidget extends StatefulWidget {
  final List<DiaryModel> diaries;
  final int dailyGoal;
  final int weeklyGoal;
  final bool isSurvey;
  const CompleteCalendarWidget(
      {super.key,
      required this.diaries,
      required this.dailyGoal,
      required this.weeklyGoal,
      required this.isSurvey});

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
              message(),
              textAlign: TextAlign.center,
              style: CustomTypography()
                  .body(color: CustomColors.textSecondaryContent),
            ),
          )
        ],
      ),
    );
  }

  String message() {
    final allEntries =
        widget.diaries.fold(0, (sum, diary) => sum + diary.currentEntry);

    final entriesLeftToday = (widget.isSurvey ? surveyGoal.daily: widget.dailyGoal) - currentEntryCount;

    if (entriesLeftToday > 1) {
      return "You've got $entriesLeftToday entries left today!";
    } else if (entriesLeftToday == 1) {
      return "You've got 1 entry left today, you are almost there!";
    } else if (entriesLeftToday == 0) {
      return "You've reached your daily goal! Great job!";
    } else if (allEntries < widget.weeklyGoal) {
      return "Way to go on that extra entry! You are getting closer to your weekly goal.";
    } else if (allEntries > widget.weeklyGoal) {
      return "You've exceeded your weekly goal! Amazing job!";
    } else if (allEntries == widget.weeklyGoal) {
      return "You've reached your weekly goal! Great job!";
    } else {
      return "";
    }
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
    double emaDailyTotalGoal = (emaGoal.daily + diaryGoal.daily).toDouble();
    double surveyTotalGoal = surveyGoal.daily.toDouble();
    final now = DateTime.now();
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
          .toList();
      final max = widget.isSurvey ? surveyTotalGoal : emaDailyTotalGoal;

      final current = diary.fold(
          0, (previousValue, element) => element.currentEntry + previousValue);
      final isAfter = d.isAfter(now);

      final percentage = current / max;

      if (diary.firstOrNull?.start.day == now.day && mounted) {
        setState(() {
          currentEntryCount = current;
        });
      }
      final showProgress = diary.isNotEmpty;

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
