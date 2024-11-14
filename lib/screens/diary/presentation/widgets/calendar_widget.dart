import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class CompleteCalendarWidget extends StatefulWidget {
  final DiaryModel diary;
  final List<DiaryModel> diaries;
  final List<StudyModel> studies;
  const CompleteCalendarWidget(
      {super.key,
      required this.diary,
      required this.diaries,
      required this.studies});

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

    final weeklyGoals =
        widget.studies.fold(0, (sum, study) => sum + study.goals.weekly);

    final diariesForToday = widget.diaries
        .where((element) =>
            element.due.year == widget.diary.due.year &&
            element.due.month == widget.diary.due.month &&
            element.due.day == widget.diary.due.day)
        .toList();

    final diaryIds = diariesForToday.map((diary) => diary.studyID).toSet();

    final studiesForTheDay = widget.studies
        .where((study) => diaryIds.contains(study.studyId))
        .toList();

    final goal =
        studiesForTheDay.fold(0, (sum, study) => sum + study.goals.daily);

    final entriesLeftToday = goal - currentEntryCount;

    if (entriesLeftToday > 1) {
      return "You've got $entriesLeftToday entries left today!";
    } else if (entriesLeftToday == 1) {
      return "You've got 1 entry left today, you are almost there!";
    } else if (entriesLeftToday == 0) {
      return "You've reached your daily goal! Great job!";
    } else if (allEntries < weeklyGoals) {
      return "Way to go on that extra entry! You are getting closer to your weekly goal.";
    } else if (allEntries > weeklyGoals) {
      return "You've exceeded your weekly goal! Amazing job!";
    } else if (allEntries == weeklyGoals) {
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
    final now = DateTime.now();
    final today = now.weekday;
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));

    final List<DateTime> _days =
        List.generate(7, (index) => monday.add(Duration(days: index)));

    for (final d in _days) {
      final isToday = d.weekday == today;
      final diaries = widget.diaries
          .where(
            (element) => element.start.day == d.day,
          )
          .toList();
      final diaryIds = diaries.map((diary) => diary.studyID).toSet();
      final studies =
          widget.studies.where((study) => diaryIds.contains(study.studyId));

      final max = studies.fold(0, (sum, study) => sum + study.goals.daily);
      final current = diaries.isNotEmpty
          ? diaries.where((diary) => diary.status == DiaryStatus.submitted).length
          : 0;
      final isAfter = d.isAfter(now);

      final percentage = current / max;

      if (d.day == now.day && mounted) {
        setState(() {
          currentEntryCount = current;
        });
      }

      final showProgress = diaries.isNotEmpty;

      days.add(dayOfTheWeek(_dayAbbreviations[d.weekday]!, isToday, percentage.isNaN ? 0.0 : percentage,
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
