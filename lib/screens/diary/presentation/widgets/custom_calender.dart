import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../theme/custom_colors.dart';

class CustomCalender extends StatelessWidget {
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final Map<DateTime, List<String>>? events;

  const CustomCalender(
      {super.key, this.rangeStart, this.rangeEnd, this.events});

  @override
  Widget build(BuildContext context) {
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
        focusedDay: DateTime.now(),
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(fontSize: 16),
          leftChevronIcon: Icon(Icons.chevron_left),
          rightChevronIcon: Icon(Icons.chevron_right),
        ),
        rangeStartDay: rangeStart,
        rangeEndDay: rangeEnd,
        calendarStyle: CalendarStyle(
          markerSize: 6,
          markerDecoration: const BoxDecoration(
              color: CustomColors.productNormal, shape: BoxShape.circle),
          todayDecoration: const BoxDecoration(
              color: CustomColors.productNormal, shape: BoxShape.circle),
          rangeHighlightColor: Colors.transparent,
          rangeStartTextStyle: CustomTypography().bodyLarge(),
          rangeStartDecoration: BoxDecoration(
              color: CustomColors.productBorderNormal,
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
        eventLoader: getDiarysForDay,
      ),
    );
  }

  List<String> getDiarysForDay(DateTime day) {
    if (events != null) {
      final date = DateTime(day.year, day.month, day.day);
      return events![date] ?? [];
    }

    return [];
  }
}
