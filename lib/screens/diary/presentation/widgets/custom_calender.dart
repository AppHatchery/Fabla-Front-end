import 'package:audio_diaries_flutter/core/usecases/calendar.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../theme/custom_colors.dart';
import '../../../home/data/study.dart';
import '../../data/diary.dart';

class CustomCalender extends StatefulWidget {
  const CustomCalender({
    super.key,
  });

  @override
  State<CustomCalender> createState() => _CustomCalenderState();
}

class _CustomCalenderState extends State<CustomCalender> {
  late PageController? pageController;
  late DateTime focusedDay;
  late DateTime today;
  late DateTime selectedDate;
  late List<DiaryModel> diaries;
  late bool isBeforeToday;
  late List<DiaryModel> diaryList;
  final DiaryRepository repository = DiaryRepository();
  Map<DateTime, List<String>>? events = {};
  late List<StudyModel> studies;

  @override
  void initState() {
    today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    pageController = null;
    focusedDay = today;
    selectedDate = today;
    diaries = fetchDiaries(today);
    diaryList = _getAllDiaries();
    events = getCalendarEvents(diaryList);
    studies = _getAllStudies();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.of(context).textScaler;
    final scaled = scaler.scale(56);
    final rowHeight = scaled < 100 ? 60.0 : scaled < 130 ? 72.0 : 80.0;

    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return Container(
      decoration: BoxDecoration(
          color: CustomColors.fillWhite,
          borderRadius: BorderRadius.circular(12),
          shape: BoxShape.rectangle,
          border: Border.all(
              color: CustomColors.productBorderNormal, width: 2)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
      child: TableCalendar(
        firstDay: DateTime.utc(2010, 10, 16),
        lastDay: DateTime.utc(2060, 3, 14),
        focusedDay: focusedDay,
        currentDay: today,
        availableGestures: AvailableGestures.none,
        headerStyle: const HeaderStyle(
            titleCentered: false,
            formatButtonVisible: false,
            rightChevronVisible: false,
            leftChevronVisible: false),
        calendarStyle: CalendarStyle(
          outsideTextStyle: CustomTypography()
              .bodyLarge(color: CustomColors.textTertiaryContent),
          todayDecoration: const BoxDecoration(
              color: CustomColors.productNormal, shape: BoxShape.circle),
        ),
        startingDayOfWeek: StartingDayOfWeek.monday,
        daysOfWeekHeight: scaler.scale(45),
        rowHeight: rowHeight,
        onCalendarCreated: (controller) {
          pageController = controller;
        },
        eventLoader: getDiariesForDay,
        calendarBuilders: CalendarBuilders(
          headerTitleBuilder: (context, day) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      getMonthYear(day),
                      style: CustomTypography().titleSmall(
                          color: CustomColors.textSecondaryContent),
                    ),
                  ),
                ),
                SizedBox(
                  child: Row(
                    children: [
                      SizedBox(
                        height: scaler.scale(24),
                        width: scaler.scale(24),
                        child: Icon(
                            Icons.chevron_left_rounded,
                            size: scaler.scale(24),
                          ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: scaler.scale(24),
                        width: scaler.scale(24),
                        child: Icon(
                            Icons.chevron_right_rounded,
                            size: scaler.scale(24),
                          ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          dowBuilder: (context, day) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          width: 0.6,
                          color: CustomColors.productBorderNormal))),
              child: Center(
                child: Text(
                  DateFormat.E().format(day)[0],
                  style: CustomTypography()
                      .titleSmall(color: CustomColors.textSecondaryContent),
                ),
              ),
            );
          },
          defaultBuilder: (context, day, focusedDay) {
            final color =
                selectedDate == day ? CustomColors.productNormal : null;

            final textColor = selectedDate == day
                ? CustomColors.textWhite
                : CustomColors.textTertiaryContent;
            return Center(
              child: Container(
                width: scaler.scale(33),
                height: scaler.scale(33),
                margin: const EdgeInsets.only(bottom: 4),
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: color),
                child: Text(
                  day.day.toString(),
                  style: CustomTypography().bodyMedium(color: textColor),
                ),
              ),
            );
          },
          todayBuilder: (context, date, time) {
            final color = (today == selectedDate || date == selectedDate)
                ? CustomColors.productNormal
                : CustomColors.productLightBackground;

            final textColor =
                (today == selectedDate || date == selectedDate)
                    ? CustomColors.textWhite
                    : CustomColors.textTertiaryContent;
            return Center(
              child: Container(
                width: scaler.scale(33),
                height: scaler.scale(33),
                margin: const EdgeInsets.only(bottom: 4),
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: color),
                child: Text(
                  date.day.toString(),
                  style: CustomTypography().bodyLarge(color: textColor),
                ),
              ),
            );
          },
          singleMarkerBuilder: (context, date, event) {
            final goal = studyGoalCheck(date);
            isBeforeToday = date.isBefore(today);
            final color = isBeforeToday
                ? CustomColors.textTertiaryContent
                : goal ? CustomColors.productNormalActive : Colors.transparent;
            return Container(
              width: 7.0,
              height: 7.0,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: color),
              margin: EdgeInsets.symmetric(
                  vertical: scaler.scale(5.0), horizontal: 1.5),
            );
          },
        ),
      ),
    );
  }

  getMonthYear(DateTime day) {
    final DateFormat formatter = DateFormat("MMMM yyyy");
    return formatter.format(day);
  }

  List<String> getDiariesForDay(DateTime day) {
    if (events != null) {
      final date = DateTime(day.year, day.month, day.day);
      return events![date] ?? [];
    }

    return [];
  }
  

  List<DiaryModel> _getAllDiaries() {
    final list = repository.getAllDiaries();
    return list;
  }

  List<StudyModel> _getAllStudies(){
    final list = repository.getAllStudies();
    return list;
  }

  //Retrieving entries for a specific date (Called From StudyCalendar)
  List<DiaryModel> fetchDiaries(DateTime date) {
    setState(() {
      diaryList = repository.getDailyDiaries(date);
    });
    return diaryList;
  }

  //function to check if the diaries belong to a study with a goal or not
  bool studyGoalCheck(DateTime date) {
    // Get diaries for the specific date
    final diariesForDate = diaryList.where((diary) {
      return DateTime(
        diary.start.year,
        diary.start.month,
        diary.start.day,
      ).isAtSameMomentAs(DateTime(date.year, date.month, date.day));
    }).toList();

    // If no diaries on this date, return false
    if (diariesForDate.isEmpty) {
      return false;
    }

    // Check if ALL diaries on this date belong to studies with goals
    for (final diary in diariesForDate) {
      // Find the study that matches this diary
      final study = studies.firstWhere(
            (s) => s.studyId == diary.studyID,
      );

      // If diary(s) is not optional display the dot
      if (study.goals.weekly >= 1 || study.goals.daily >= 1) {
        return true;
      }
    }

    // Optional Diary(s) - no dot displayed
    return false;
  }
}
