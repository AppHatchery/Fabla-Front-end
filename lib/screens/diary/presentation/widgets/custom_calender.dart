import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../theme/custom_colors.dart';
import '../../data/diary.dart';

class CustomCalender extends StatefulWidget {
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final List<DiaryModel>? diaries;
  final Function? selectDate;

  const CustomCalender(
      {super.key,
      this.rangeStart,
      this.rangeEnd,
      this.diaries,
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
    return GestureDetector(
        onTap: () {
          PendoService.track("CalenderTap", {
            "study_day": "${DateTime.now()}",
          });
        },
        child: Container(
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
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: CustomTypography()
                  .bodyLarge(color: CustomColors.textNormalContent),
              leftChevronIcon: const Icon(Icons.chevron_left_rounded),
              rightChevronIcon: const Icon(Icons.chevron_right_rounded),
            ),
            rangeStartDay: widget.rangeStart,
            rangeEndDay: widget.rangeEnd,
            startingDayOfWeek: StartingDayOfWeek.monday,
            daysOfWeekHeight: 20,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              markerSize: 6,
              markerDecoration: const BoxDecoration(
                  color: CustomColors.productNormal, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                  color: CustomColors.productNormal,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: CustomColors.productNormal, width: 4)),
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
            onDaySelected: _onDaySelected,
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final hasDiary = widget.diaries?.where((element) => isSameDay(
                        element.start,
                        DateTime(day.year, day.month, day.day, 4, 0, 0))) ??
                    [];

                final isComplete = hasDiary
                        .where((element) => isSameDay(element.start,
                            DateTime(day.year, day.month, day.day, 4, 0, 0)))
                        .firstOrNull
                        ?.status ==
                    DiaryStatus.submitted;

                return Container(
                  margin: const EdgeInsets.all(4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: hasDiary.isNotEmpty
                          ? isComplete
                              ? const Color(0xFF1FBE4C)
                              : const Color(0xFFB4D5FF).withOpacity(0.5)
                          : Colors.transparent,
                      shape: BoxShape.circle),
                  child: Text(
                    day.day.toString(),
                    style: CustomTypography().bodyLarge(
                        color: isComplete
                            ? CustomColors.fillWhite
                            : CustomColors.textTertiaryContent),
                  ),
                );
              },
              dowBuilder: (context, day) {
                final text = DateFormat.E().format(day);
                return Center(
                  child: Text(
                    text.substring(0, 1),
                    style: CustomTypography()
                        .bodyLarge(color: CustomColors.textSecondaryContent),
                  ),
                );
              },
            ),
          ),
        ));
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
    PendoService.track("CalenderTap", {
      "study_day": "${DateTime.now()}",
    });
  }
}
