import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:audio_diaries_flutter/theme/resources/custom_clippers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class StudyCalendar extends StatefulWidget {
  const StudyCalendar({super.key});

  @override
  State<StudyCalendar> createState() => _StudyCalendarState();
}

class _StudyCalendarState extends State<StudyCalendar> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return SizedBox(
      height: height,
      width: width,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
          Expanded(
              child: Container(
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
          ))
        ],
      ),
    );
  }

  Widget calendar() {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

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
            focusedDay: today,
            rangeStartDay: today.subtract(const Duration(days: 15)),
            rangeEndDay: today.add(const Duration(days: 15)),
            headerStyle: const HeaderStyle(
                titleCentered: false,
                formatButtonVisible: false,
                rightChevronVisible: false,
                leftChevronVisible: false),
            calendarStyle: CalendarStyle(
              outsideTextStyle: CustomTypography()
                  .bodyLarge(color: CustomColors.textTertiaryContent),
              rangeStartTextStyle: CustomTypography()
                  .bodyLarge(color: CustomColors.textTertiaryContent),
              withinRangeTextStyle: CustomTypography()
                  .bodyLarge(color: CustomColors.textTertiaryContent),
              rangeHighlightColor: CustomColors.productLightBackground,
              rangeStartDecoration: const BoxDecoration(
                color: CustomColors.productLightBackground,
                shape: BoxShape.circle,
              ),
              todayDecoration: const BoxDecoration(
                  color: CustomColors.productNormalActive,
                  shape: BoxShape.circle),
            ),
            startingDayOfWeek: StartingDayOfWeek.monday,
            daysOfWeekHeight: 45,
            calendarBuilders: CalendarBuilders(
              headerTitleBuilder: (context, day) => Padding(
                padding: const EdgeInsets.only(bottom:12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        getMonthYear(day),
                        style: CustomTypography()
                            .titleSmall(color: CustomColors.textSecondaryContent),
                      ),
                    ),
                    SizedBox(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => null,
                            child: const SizedBox(
                                height: 24,
                                width: 24,
                                child: Icon(Icons.chevron_left_rounded)),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
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
              dowBuilder: (context, day) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.only(bottom: 8),
                decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            width: 1,
                            color: CustomColors.productBorderNormal))),
                child: Center(
                  child: Text(
                    DateFormat.E().format(day)[0],
                    style: CustomTypography()
                        .titleSmall(color: CustomColors.textSecondaryContent),
                  ),
                ),
              ),
              defaultBuilder: (context, day, focusedDay) => Container(
                margin: const EdgeInsets.all(4),
                alignment: Alignment.center,
                child: Text(
                  day.day.toString(),
                  style: CustomTypography()
                      .bodyLarge(color: CustomColors.textSecondaryContent),
                ),
              ),
              rangeEndBuilder: (context, day, focusedDay) => Container(
                margin: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: CustomColors.productLightBackground,
                  shape: BoxShape.circle,
                ),
                child: ClipPath(
                  clipper: StarClipper(8),
                  child: Container(
                    alignment: Alignment.center,
                    color: CustomColors.yellowDark,
                    child: Text(
                      day.day.toString(),
                      style: CustomTypography()
                          .bodyLarge(color: CustomColors.textWhite),
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget entries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Weekly Entries", style: CustomTypography().titleSmall()),
        const SizedBox(height: 4),
        Text(getThisWeek(),
            style: CustomTypography()
                .bodyLarge(color: CustomColors.textTertiaryContent)),
      ],
    );
  }

  getThisWeek() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final DateFormat formatter = DateFormat("EEEE, MMM d");

    return "${formatter.format(monday)} - ${formatter.format(sunday)}";
  }

  getMonthYear(DateTime day) {
    final DateFormat formatter = DateFormat("MMMM yyyy");
    return formatter.format(day);
  }
}
