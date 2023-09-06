import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../theme/custom_colors.dart';

class CustomCalender extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  const CustomCalender({super.key, this.startDate, this.endDate});

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
        rangeStartDay: startDate,
        rangeEndDay: endDate,
        calendarStyle: const CalendarStyle(markerSize: 1),
      ),
    );
  }
}
