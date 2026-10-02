import 'dart:math' as math;

import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

/// Circle behind a day number in a [TableCalendar] cell.
///
/// Grows with the system text scale until it fills the cell (leaving room for
/// the bottom margin and event markers); past that the number shrinks to stay
/// inside the circle.
class CalendarDayCircle extends StatelessWidget {
  final String label;
  final TextStyle style;
  final Color? color;
  final double baseSize;

  const CalendarDayCircle({
    super.key,
    required this.label,
    required this.style,
    this.color,
    this.baseSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final preferred = MediaQuery.textScalerOf(context).scale(baseSize);
    return LayoutBuilder(builder: (context, constraints) {
      final diameter =
          math.min(preferred, constraints.biggest.shortestSide - 8);
      return Center(
        child: Container(
          width: diameter,
          height: diameter,
          margin: const EdgeInsets.only(bottom: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: style),
          ),
        ),
      );
    });
  }
}

class CustomDatePicker extends StatefulWidget {
  final DateTime? date;
  final Function(DateTime date) onSelect;
  const CustomDatePicker({super.key, this.date, required this.onSelect});

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late PageController? pageController;
  late DateTime focusedDay;
  late DateTime today;
  late DateTime selectedDate;

  @override
  void initState() {
    today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    pageController = null;
    selectedDate = widget.date ?? today;
    focusedDay = selectedDate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.of(context).textScaler;
    final scaled = scaler.scale(56);
    final rowHeight = scaled < 100
        ? 60.0
        : scaled < 130
            ? 72.0
            : 80.0;

    return Container(
      decoration: BoxDecoration(
          color: CustomColors.fillWhite,
          borderRadius: BorderRadius.circular(20),
          shape: BoxShape.rectangle,
          border:
              Border.all(width: 2, color: CustomColors.productBorderNormal)),
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
        daysOfWeekHeight: scaler.scale(45).clamp(35.0, 52.0),
        rowHeight: rowHeight,
        onDaySelected: _onDaySelected,
        onCalendarCreated: (controller) {
          pageController = controller;
        },
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
                      style: CustomTypography()
                          .titleSmall(color: CustomColors.textSecondaryContent),
                    ),
                  ),
                ),
                SizedBox(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => pageController?.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease),
                        child: SizedBox(
                            height: scaler.scale(24),
                            width: scaler.scale(24),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: scaler.scale(24),
                            )),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => pageController?.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease),
                        child: SizedBox(
                            height: scaler.scale(24),
                            width: scaler.scale(24),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: scaler.scale(24),
                            )),
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    DateFormat.E().format(day)[0],
                    style: CustomTypography()
                        .titleSmall(color: CustomColors.textSecondaryContent),
                  ),
                ),
              ),
            );
          },
          defaultBuilder: (context, day, focusedDay) {
            final _day = DateTime(day.year, day.month, day.day, 0, 0, 0);
            final _selected = DateTime(selectedDate.year, selectedDate.month,
                selectedDate.day, 0, 0, 0);

            final isPast = _day.isBefore(DateTime.now());
            final color = _selected == _day ? CustomColors.productNormal : null;

            final textColor = _selected == _day
                ? CustomColors.textWhite
                : isPast ? CustomColors.textTertiaryContent : CustomColors.textNormalContent;
            return CalendarDayCircle(
              label: day.day.toString(),
              style: CustomTypography().bodyMedium(color: textColor),
              color: color,
            );
          },
          todayBuilder: (context, date, time) {
            final _day = DateTime(date.year, date.month, date.day, 0, 0, 0);
            final _selected = DateTime(selectedDate.year, selectedDate.month,
                selectedDate.day, 0, 0, 0);
            final color = (today == _selected || _day == _selected)
                ? CustomColors.productNormal
                : CustomColors.productLightBackground;

            final textColor = (today == _selected || _day == _selected)
                ? CustomColors.textWhite
                : CustomColors.textTertiaryContent;
            return CalendarDayCircle(
              label: date.day.toString(),
              style: CustomTypography().bodyLarge(color: textColor),
              color: color,
            );
          },
        ),
      ),
    );
  }

  _onDaySelected(DateTime selectedDay, DateTime focusedDate) {
      setState(() {
        //reloading diaries bases on new selected date

        focusedDay = selectedDay;
        selectedDate = selectedDay;
      });
      widget.onSelect(selectedDay);
  }

  getMonthYear(DateTime day) {
    final DateFormat formatter = DateFormat("MMMM yyyy");
    return formatter.format(day);
  }
}
