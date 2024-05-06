import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/empty_state.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:audio_diaries_flutter/theme/resources/custom_clippers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:table_calendar/table_calendar.dart';

class StudyCalendar extends StatefulWidget {
  final List<DiaryModel> diaries;
  final ValueChanged<bool> refresh;
  final String Function() getPageName;
  final List<DiaryModel> Function(BuildContext context, DateTime date)
      fetchDiaries;
  const StudyCalendar(
      {super.key,
      required this.diaries,
      required this.refresh,
      required this.getPageName,
      required this.fetchDiaries});

  @override
  State<StudyCalendar> createState() => _StudyCalendarState();
}

class _StudyCalendarState extends State<StudyCalendar> {
  late List<DateTime> selectedRange;
  late PageController? pageController;
  late DateTime focusedDay;
  late DateTime startDate;
  late DateTime endDate;
  late DateTime today;
  late DateTime selectedDate;
  late List<DiaryModel> diaries;
  late bool isBeforeToday;
  late List<DiaryModel> diaryList;
  Map<DateTime, List<String>>? events = {};

  @override
  void initState() {
    today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    startDate = DateTime(
        today.subtract(const Duration(days: 15)).year,
        today.subtract(const Duration(days: 15)).month,
        today.subtract(const Duration(days: 15)).day);
    endDate = DateTime(
        today.add(const Duration(days: 15)).year,
        today.add(const Duration(days: 15)).month,
        today.add(const Duration(days: 15)).day,
        0);
    pageController = null;
    final monday = today.subtract(Duration(days: today.weekday - 1));
    selectedRange =
        List.generate(7, (index) => monday.add(Duration(days: index)));
    focusedDay = today;
    selectedDate = today;
    diaries = widget.diaries;
    diaryList = _getAllDiaries();

    for (DiaryModel diary in diaryList) {
      events!.putIfAbsent(diary.start, () => []);
      events![diary.start]!.add(diary.start.toString());
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
                          "0",
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2060, 3, 14),
            focusedDay: focusedDay,
            currentDay: today,
            // rangeStartDay: startDate,
            // rangeEndDay: endDate,
            availableGestures: AvailableGestures.horizontalSwipe,
            headerStyle: const HeaderStyle(
                titleCentered: false,
                formatButtonVisible: false,
                rightChevronVisible: false,
                leftChevronVisible: false),
            calendarStyle: CalendarStyle(
              outsideTextStyle: CustomTypography()
                  .bodyLarge(color: CustomColors.textTertiaryContent),
              rangeStartTextStyle:
                  CustomTypography().bodyLarge(color: Colors.transparent),
              withinRangeTextStyle:
                  CustomTypography().bodyLarge(color: Colors.transparent),
              rangeHighlightColor: CustomColors.productLightBackground,
              todayDecoration: const BoxDecoration(
                  color: CustomColors.productNormal, shape: BoxShape.circle),
            ),
            startingDayOfWeek: StartingDayOfWeek.monday,
            daysOfWeekHeight: 45,
            // rowHeight: 55, - affecting star when lower than 52
            onDaySelected: _onDaySelected,
            onCalendarCreated: (controller) {
              pageController = controller;
            },
            eventLoader: getDiariesForDay,
            calendarBuilders: CalendarBuilders(
              singleMarkerBuilder: (context, date, event) {
                isBeforeToday = date.isBefore(today);
                final color = isBeforeToday
                    ? CustomColors.textTertiaryContent
                    : CustomColors.productDark;
                return Container(
                  width: 7.0,
                  height: 7.0,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color),
                  margin: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 1.5),
                );
              },
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
              todayBuilder: (context, date, time) {
                final color = (today == selectedDate || date == selectedDate)
                    ? CustomColors.productNormal
                    : CustomColors.productLightBackground;

                final textColor =
                    (today == selectedDate || date == selectedDate)
                        ? CustomColors.textWhite
                        : CustomColors.textTertiaryContent;

                return Container(
                  width: 40,
                  height: 40,
                  margin: EdgeInsets.all(4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(100)),
                    color: color,
                  ),
                  child: Text(
                    date.day.toString(),
                    style: CustomTypography().bodyLarge(color: textColor),
                  ),
                );
              },
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
                final isDayInRange = selectedRange.contains(day);
                final isToday = selectedRange.contains(today);
                final isMonday = selectedRange.first == day;
                final isSunday = selectedRange.last == day;

                final margin = isDayInRange
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.all(4);

                final borderRadius = BorderRadius.only(
                  topLeft: isMonday ? const Radius.circular(100) : Radius.zero,
                  bottomLeft:
                      isMonday ? const Radius.circular(100) : Radius.zero,
                  topRight: isSunday ? const Radius.circular(100) : Radius.zero,
                  bottomRight:
                      isSunday ? const Radius.circular(100) : Radius.zero,
                );

                final color = isDayInRange ? CustomColors.productNormal : null;

                final textColor = isDayInRange
                    ? CustomColors.textWhite
                    : CustomColors.textTertiaryContent;
                return Container(
                  width: 40,
                  height: 40,
                  margin: margin,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    color: color,
                  ),
                  child: Text(
                    day.day.toString(),
                    style: CustomTypography().bodyLarge(color: textColor),
                  ),
                );
              },
              // rangeHighlightBuilder: (context, day, isWithinRange) {
              //   final isDayInRange = selectedRange.contains(day);
              //
              //   final color = isDayInRange
              //       ? CustomColors.productNormal
              //       : Colors.transparent;
              //
              //   // final radius = BorderRadius.circular(100);
              //
              //   return Container(
              //     margin: const EdgeInsets.symmetric(vertical: 4),
              //     alignment: Alignment.center,
              //     decoration: isDayInRange
              //         ? BoxDecoration(shape: BoxShape.circle, color: color)
              //         : BoxDecoration(shape: BoxShape.circle, color: color),
              //     child: Text(
              //       day.day.toString(),
              //       style: CustomTypography().bodyLarge(
              //           color: isDayInRange
              //               ? CustomColors.textWhite
              //               : CustomColors.textTertiaryContent),
              //     ),
              //   );
              // },
            ),
          ),
        )
      ],
    );
  }

  _onDaySelected(DateTime selectedDay, DateTime focusedDate) {
    // if (!selectedRange.contains(selectedDay)) {
    final List<DateTime> range = [selectedDay];

    setState(() {
      selectedRange = range;
      focusedDay = focusedDate;
      selectedDate = selectedDay;

      //reloading diaries bases on new selected date
      diaries = widget.fetchDiaries(context, selectedDate);
    });
    // }
  }

  Widget entries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    child: DiaryCardCalendar(
                      diary: diaries[index],
                      refresh: (value) => widget.refresh(value),
                      getPageName: widget.getPageName,
                    ),
                  );
                },
              )
            : const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: FreeDayWidget(),
              )
      ],
    );
  }

  getThisWeek() {
    final DateFormat formatter = DateFormat("MMMM d");
    final DateFormat yearFormatter = DateFormat.y();

    final start = formatter.format(selectedRange.first);
    final end = formatter.format(selectedRange.last);
    final year = yearFormatter.format(selectedRange.first);
    return "$start - $end, $year";
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
    final DiaryRepository repository = DiaryRepository();
    final list = repository.getAllDiaries();
    return list;
  }
}
