import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../theme/custom_colors.dart';

class CustomCalender extends StatefulWidget {
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final Map<DateTime, List<String>>? events;
  final Function? selectDate;

  const CustomCalender(
      {super.key,
      this.rangeStart,
      this.rangeEnd,
      this.events,
      this.selectDate});

  @override
  State<CustomCalender> createState() => _CustomCalenderState();
}

class _CustomCalenderState extends State<CustomCalender> {
  DateTime? _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    _focusedDay ??=
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _selectedDay = _focusedDay;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return Container(
      decoration: BoxDecoration(
        color: CustomColors.fillWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CustomColors.productBorderNormal,
          width: 2,
        ),
        shape: BoxShape.rectangle,
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2010, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay ?? today,
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(fontSize: 16),
          leftChevronIcon: Icon(Icons.chevron_left),
          rightChevronIcon: Icon(Icons.chevron_right),
        ),
        rangeStartDay: widget.rangeStart,
        rangeEndDay: widget.rangeEnd,
        calendarStyle: CalendarStyle(
          markerSize: 6,
          markerDecoration: const BoxDecoration(
              color: CustomColors.productNormal, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(
              color: CustomColors.productNormal,
              shape: BoxShape.circle,
              border: Border.all(color: CustomColors.productNormal, width: 4)),
          selectedDecoration: BoxDecoration(
              color: today == _selectedDay
                  ? CustomColors.productNormal
                  : CustomColors.yellowDark,
              shape: BoxShape.circle,
              border: Border.all(
                  color: today == _selectedDay
                      ? CustomColors.productNormal
                      : CustomColors.yellowDark,
                  width: 4)),
          rangeHighlightColor: Colors.transparent,
          rangeStartTextStyle: CustomTypography().bodyLarge(
              color: today == widget.rangeStart
                  ? CustomColors.fillWhite
                  : Colors.black),
          rangeStartDecoration: BoxDecoration(
              color: today == widget.rangeStart
                  ? CustomColors.productNormal
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: CustomColors.yellowDark, width: 4)),
          withinRangeDecoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: CustomColors.yellowDark, width: 4)),
          withinRangeTextStyle: CustomTypography().bodyLarge(),
          rangeEndDecoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: CustomColors.yellowDark, width: 4)),
          rangeEndTextStyle: CustomTypography().bodyLarge(),
          defaultTextStyle: CustomTypography().bodyLarge(),
        ),
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _getDiariesForDay,
        onDaySelected: _onDaySelected,
      ),
    );
  }

  List<String> _getDiariesForDay(DateTime day) {
    if (widget.events != null) {
      final date = DateTime(day.year, day.month, day.day);
      return widget.events![date] ?? [];
    }

    return [];
  }

  _onDaySelected(DateTime? selectedDay, DateTime? focusedDay) {
    if (widget.selectDate != null &&
        !isSameDay(_selectedDay, selectedDay) &&
        selectedDay != null) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay!;
      });

      final date = DateTime(
          selectedDay.year, selectedDay.month, selectedDay.day, 4, 0, 0);
      widget.selectDate!(date);
    }
  }
}
