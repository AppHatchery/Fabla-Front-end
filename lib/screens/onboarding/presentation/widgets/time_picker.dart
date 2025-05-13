import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/theme/components/time_picker.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

class OnboardingTimePicker extends StatefulWidget {
  final String? time;
  final String subtitle;
  final ValueChanged<String> onChanged;
  const OnboardingTimePicker(
      {super.key, this.time, required this.subtitle, required this.onChanged});

  @override
  State<OnboardingTimePicker> createState() => _OnboardingTimePickerState();
}

class _OnboardingTimePickerState extends State<OnboardingTimePicker> {
  late MaterialLocalizations localizations = MaterialLocalizations.of(context);

  TimeOfDay? time;

  @override
  void initState() {
    if (widget.time != null) {
      time = timeOfDayFromString(widget.time!);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
          color: CustomColors.fillWhite,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: CustomColors.productBorderNormal, width: 2)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time != null
                    ? localizations.formatTimeOfDay(time!)
                    : 'Select Time',
                style: CustomTypography()
                    .titleMedium(color: CustomColors.textNormalContent),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                  onPressed: () => pickTime(time),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: CustomColors.productNormal,
                    size: 24,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  void pickTime(TimeOfDay? date) async {
    final _time = await showModalBottomSheet(
        backgroundColor: CustomColors.fillWhite,
        isScrollControlled: true,
        enableDrag: false,
        context: context,
        routeSettings: RouteSettings(name: "/TimePickerModal"),
        builder: (context) => LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                child: CustomTimePicker(
                  title: widget.subtitle,
                  date: date,
                  onDelete: null,
                  minuteInterval: 1,
                ),
              );
            }));

    if (_time != null) {
      setState(() {
        time = _time;
      });

      widget.onChanged(
          localizations.formatTimeOfDay(time!, alwaysUse24HourFormat: true));
    }
  }
}

class TimeElapsedPicker extends StatefulWidget {
  final String? time;
  final String subtitle;
  final ValueChanged<String> onChanged;
  const TimeElapsedPicker(
      {super.key, this.time, required this.subtitle, required this.onChanged});

  @override
  State<TimeElapsedPicker> createState() => _TimeElapsedPickerState();
}

class _TimeElapsedPickerState extends State<TimeElapsedPicker> {
  Duration? elapsed;

  @override
  void initState() {
    getDuration();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
          color: CustomColors.fillWhite,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: CustomColors.productBorderNormal, width: 2)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                elapsed != null
                    ? "${elapsed!.inHours.toString().padLeft(2, '0')} h ${elapsed!.inMinutes.remainder(60).toString().padLeft(2, '0')} min"
                    : 'Select Time',
                style: CustomTypography()
                    .titleMedium(color: CustomColors.textNormalContent),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                  onPressed: () => pickTime(elapsed),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: CustomColors.productNormal,
                    size: 24,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  void pickTime(Duration? duration) async {
    final _elapsed = await showModalBottomSheet(
        backgroundColor: CustomColors.fillWhite,
        isScrollControlled: true,
        enableDrag: false,
        context: context,
        routeSettings: RouteSettings(name: "/TimePickerModal"),
        builder: (context) => LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                child: CustomTimeElapsedPicker(
                  title: widget.subtitle,
                  duration: elapsed,
                ),
              );
            }));

    if (_elapsed != null) {
      setState(() {
        elapsed = _elapsed;
      });

      widget.onChanged(
          "${elapsed!.inHours.toString().padLeft(2, '0')}:${elapsed!.inMinutes.remainder(60).toString().padLeft(2, '0')}");
    }
  }

  void getDuration() {
    if (widget.time != null) {
      elapsed = Duration(
          hours: int.parse(widget.time!.split(":")[0]),
          minutes: int.parse(widget.time!.split(":")[1]));
    }
  }
}
