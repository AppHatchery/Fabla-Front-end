import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class CompleteCalendarWidget extends StatefulWidget {
  const CompleteCalendarWidget({super.key});

  @override
  State<CompleteCalendarWidget> createState() => _CompleteCalendarWidgetState();
}

class _CompleteCalendarWidgetState extends State<CompleteCalendarWidget> {
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
              "You've got 1 entry left today",
              style: CustomTypography().body(color: CustomColors.textSecondaryContent),
            ),
          )
        ],
      ),
    );
  }

  Widget dayOfTheWeek(String day, String date, bool isToday, bool? isComplete) {
    return Column(
      children: [
        Text(
          day.toString(),
          style: CustomTypography().bodyMedium(
            color: isToday ? Colors.black : CustomColors.textTertiaryContent,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(
          height: 6,
        ),
        isToday ? const CircularProgressIndicator(
          strokeWidth: 2,
          value: 0.8,
          backgroundColor: CustomColors.productBorderNormal,
          color: CustomColors.productNormal,
        ) : DottedBorder(
          borderType: BorderType.Circle,
          strokeWidth: 2,
          color: CustomColors.productBorderNormal,
          dashPattern: const [6],
          child: const SizedBox(
            height: 30,
            width: 30,
           
          ),
        ),
      ],
    );
  }

  void prepare() async {
    days.clear();
    final now = DateTime.now();
    final today = now.weekday;
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));

    List<DateTime> _days = [];

    for (int i = 0; i < 7; i++) {
      _days.add(monday.add(Duration(days: i)));
    }

    for (final d in _days) {
      final isToday = d.weekday == today;

      days.add(dayOfTheWeek(
          _dayAbbreviations[d.weekday]!, d.day.toString(), isToday, false));
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
