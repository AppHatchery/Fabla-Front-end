import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/empty_state.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class StudyCalendar extends StatefulWidget {
  final ValueChanged<bool> refresh;
  final String Function() getPageName;

  const StudyCalendar({
    super.key,
    required this.refresh,
    required this.getPageName,
  });

  @override
  State<StudyCalendar> createState() => _StudyCalendarState();
}

class _StudyCalendarState extends State<StudyCalendar> {
  late PageController? pageController;
  late DateTime focusedDay;
  late DateTime today;
  late DateTime selectedDate;
  late List<DiaryModel> diaries;
  late bool isBeforeToday;
  late List<DiaryModel> diaryList;
  final DiaryRepository repository = DiaryRepository();
  Map<DateTime, List<String>>? events = {};
  int activeDays = 0;

  @override
  void initState() {
    today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    pageController = null;
    focusedDay = today;
    selectedDate = today;
    activeDays = repository.countSubmittedDays();
    diaries = fetchDiaries(today);
    diaryList = _getAllDiaries();

    for (DiaryModel diary in diaryList) {
      final date =
          DateTime(diary.start.year, diary.start.month, diary.start.day);
      events!.putIfAbsent(date, () => []);
      if (events![date]!.isEmpty) {
        events![date]!.add(diary.start.toString());
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return SizedBox(
      height: height,
      width: width,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: CustomColors.yellowTertiary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                CupertinoIcons.clear,
                                color: CustomColors.yellowDark,
                                size: 20,
                              )),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Study Progress",
                          style: CustomTypography()
                              .titleLarge(color: CustomColors.yellowDark),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Expanded(
                        child: SizedBox(),
                      )
                    ],
                  ),
                  //Days active
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeDays.toString(),
                          style: CustomTypography().headlineLargeCustom(
                              color: CustomColors.yellowDark, fontSize: 64.sp),
                        ),
                        Text(
                          "Days active in the Winship Study",
                          style: CustomTypography()
                              .titleSmall(color: CustomColors.yellowDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: width,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              color: CustomColors.fillNormal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  calendar(),
                  const SizedBox(height: 12),
                  entries(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget calendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Study Calendar",
          style: CustomTypography().titleLarge(),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: CustomColors.fillWhite,
            borderRadius: BorderRadius.circular(12),
            shape: BoxShape.rectangle,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
          child: TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2060, 3, 14),
            focusedDay: focusedDay,
            currentDay: today,
            availableGestures: AvailableGestures.horizontalSwipe,
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
            daysOfWeekHeight: 45,
            onDaySelected: _onDaySelected,
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
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        getMonthYear(day),
                        style: CustomTypography().titleSmall(
                            color: CustomColors.textSecondaryContent),
                      ),
                    ),
                    SizedBox(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => pageController?.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease),
                            child: const SizedBox(
                                height: 24,
                                width: 24,
                                child: Icon(Icons.chevron_left_rounded)),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => pageController?.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease),
                            child: const SizedBox(
                                height: 24,
                                width: 24,
                                child: Icon(Icons.chevron_right_rounded)),
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
                    width: 33,
                    height: 33,
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
                    width: 33,
                    height: 33,
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
                isBeforeToday = date.isBefore(today);
                final color = isBeforeToday
                    ? CustomColors.textTertiaryContent
                    : CustomColors.productNormalActive;
                return Container(
                  width: 7.0,
                  height: 7.0,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color),
                  margin: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 1.5),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  _onDaySelected(DateTime selectedDay, DateTime focusedDate) {
    if (selectedDay.isAfter(DateTime.now()) ||
        DateUtils.isSameDay(DateTime.now(), selectedDay)) {
      setState(() {
        //reloading diaries bases on new selected date

        focusedDay = selectedDay;
        selectedDate = selectedDay;
        diaries = fetchDiaries(selectedDate);
      });
    }
  }

  Widget entries() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          DateUtils.isSameDay(DateTime.now(), selectedDate)
              ? "Entries Due Today ${DateFormat("MMMM d").format(selectedDate)}, ${DateFormat.y().format(selectedDate)}  "
              : "Entries Due ${DateFormat("MMMM d").format(selectedDate)}, ${DateFormat.y().format(selectedDate)} ",
          style: CustomTypography().titleSmall()),
      const SizedBox(height: 4),

      //Scrollable widget to display all entries due on selected date
      diaries.isNotEmpty
          ? ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: diaries.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: DiaryCard(
                    diary: diaries[index],
                    refresh: (value) {
                      if (value) {
                        setState(() {
                          widget.refresh(value);
                        });
                      }
                    },
                    getPageName: widget.getPageName,
                  ),
                );
              },
            )
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: FreeDayWidget(),
            )
    ]);
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

  //Retrieving entries for a specific date (Called From StudyCalendar)
  List<DiaryModel> fetchDiaries(DateTime date) {
    setState(() {
      diaryList = repository.getDailyDiaries(date);
    });
    return diaryList;
  }
}
