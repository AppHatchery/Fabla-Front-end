import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

import '../custom_colors.dart';

class CustomTimePicker extends StatefulWidget {
  final String title;
  final TimeOfDay? date;
  final VoidCallback? onDelete;
  final int minuteInterval;
  const CustomTimePicker(
      {super.key,
      this.title = "Reminder Time",
      this.date,
      this.onDelete,
      this.minuteInterval = 5});

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late TimeOfDay _date;
  late FixedExtentScrollController hoursController;
  late FixedExtentScrollController minutesController;
  late FixedExtentScrollController periodController;
  @override
  void initState() {
    _date = widget.date ?? const TimeOfDay(hour: 0, minute: 0);
    hoursController = FixedExtentScrollController(
      initialItem: (_date.hour % 12) == 0 ? 12 : (_date.hour % 12) - 1,
    );
    minutesController = FixedExtentScrollController(
      initialItem: _date.minute,
    );
    periodController = FixedExtentScrollController(
      initialItem: (_date.hour >= 12) ? 1 : 0,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(flex: 1, child: SizedBox()),
                Expanded(
                    flex: 5,
                    child: Text(
                      widget.title,
                      style: CustomTypography().titleLarge(),
                      textAlign: TextAlign.center,
                    )),
                Expanded(
                  flex: 1,
                  child: Container(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: CustomColors.textNormalContent,
                          ))),
                )
              ],
            ),
            const SizedBox(
              height: 32,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: width / 2,
                  child: Center(
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            child: ListWheelScrollView.useDelegate(
                              controller: hoursController,
                              onSelectedItemChanged: (value) => setState(() {
                                _date = _date.replacing(hour: value + 1);
                              }),
                              physics: const FixedExtentScrollPhysics(),
                              perspective: 0.01,
                              diameterRatio: 1,
                              itemExtent: 50,
                              overAndUnderCenterOpacity: 0.3,
                              squeeze: 2,
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  return Hours(hour: index + 1);
                                },
                                childCount: 12,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 200,
                            width: 80,
                            child: ListWheelScrollView.useDelegate(
                              controller: minutesController,
                              onSelectedItemChanged: (value) => setState(() {
                                _date = _date.replacing(
                                    minute: value * widget.minuteInterval);
                              }),
                              physics: const FixedExtentScrollPhysics(),
                              perspective: 0.01,
                              diameterRatio: 1,
                              itemExtent: 50,
                              overAndUnderCenterOpacity: 0.3,
                              squeeze: 2,
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  return Minutes(
                                      mins: index * widget.minuteInterval);
                                },
                                childCount: 60 ~/ widget.minuteInterval,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            // height: 200,
                            // width: 80,
                            child: ListWheelScrollView.useDelegate(
                              controller: periodController,
                              physics: const FixedExtentScrollPhysics(),
                              perspective: 0.01,
                              diameterRatio: 1,
                              itemExtent: 50,
                              overAndUnderCenterOpacity: 0.3,
                              squeeze: 2,
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  return Period(
                                      period: index == 0 ? "AM" : "PM");
                                },
                                childCount: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 24,
            ),
            CustomElevatedButton(onClick: () => save(), text: "SAVE"),
          ],
        ),
      ),
    );
  }

  void save() {
    if (periodController.selectedItem == 1 && _date.hour < 12) {
      // If PM is selected and the hour is before noon, add 12 hours.
      _date = TimeOfDay(hour: _date.hour + 12, minute: _date.minute);
    } else if (periodController.selectedItem == 0 && _date.hour >= 12) {
      // If AM is selected and the hour is 12 or greater, subtract 12 hours.
      _date = TimeOfDay(hour: _date.hour - 12, minute: _date.minute);
    }
    Navigator.pop(context, _date);
  }
}

class Minutes extends StatelessWidget {
  final int mins;
  const Minutes({super.key, required this.mins});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
          child: Center(
        child: Text(
          twoDigits(mins),
          style: CustomTypography().titleSmall(),
        ),
      )),
    );
  }

  String twoDigits(int n) => n.toString().padLeft(2, "0");
}

class Hours extends StatelessWidget {
  final int hour;
  const Hours({super.key, required this.hour});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
          child: Center(
        child: Text(
          hour.toString(),
          style: CustomTypography().titleSmall(),
        ),
      )),
    );
  }
}

class HoursAndMinutes extends StatelessWidget {
  final double number;
  const HoursAndMinutes({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
          child: Center(
        child: Text(
          number % 1 == 0
              ? number.toInt().toString()
              : number.toStringAsFixed(1),
          style: CustomTypography().titleSmall(),
        ),
      )),
    );
  }
}

class Period extends StatelessWidget {
  final String period;
  const Period({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
          child: Center(
        child: Text(
          period,
          style: CustomTypography().titleSmall(),
        ),
      )),
    );
  }
}

class CustomTimeElapsedPicker extends StatefulWidget {
  final String title;
  final Duration? duration;
  const CustomTimeElapsedPicker(
      {super.key, required this.title, this.duration});

  @override
  State<CustomTimeElapsedPicker> createState() =>
      _CustomTimeElapsedPickerState();
}

class _CustomTimeElapsedPickerState extends State<CustomTimeElapsedPicker> {
  late Duration duration;
  late FixedExtentScrollController hoursController;

  @override
  void initState() {
    duration = widget.duration ?? const Duration(hours: 0, minutes: 0);

    hoursController = FixedExtentScrollController(
      initialItem: (duration.inMinutes / 30).round(),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(flex: 1, child: SizedBox()),
                Expanded(
                    flex: 5,
                    child: Text(
                      widget.title,
                      style: CustomTypography().titleLarge(),
                      textAlign: TextAlign.center,
                    )),
                Expanded(
                  flex: 1,
                  child: Container(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: CustomColors.textNormalContent,
                          ))),
                )
              ],
            ),
            const SizedBox(
              height: 32,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: width / 2,
                  child: Center(
                    child: Row(
                      children: [
                        Text("Hours:",
                            style: CustomTypography().titleMedium(
                                color: CustomColors.textTertiaryContent)),
                        Expanded(
                          child: SizedBox(
                            child: ListWheelScrollView.useDelegate(
                              controller: hoursController,
                              onSelectedItemChanged: (value) {
                                final totalHours = value * 0.5;
                                final hours = totalHours.floor();
                                final minutes =
                                    ((totalHours - hours) * 60).round();
                                setState(() {
                                  duration = Duration(
                                    hours: hours,
                                    minutes: minutes,
                                  );
                                });
                              },
                              physics: const FixedExtentScrollPhysics(),
                              perspective: 0.01,
                              diameterRatio: 1,
                              itemExtent: 50,
                              overAndUnderCenterOpacity: 0.3,
                              squeeze: 2,
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  return HoursAndMinutes(number: 0.5 * index);
                                },
                                childCount: 48,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 24,
            ),
            CustomElevatedButton(onClick: () => save(), text: "SAVE"),
          ],
        ),
      ),
    );
  }

  void save() {
    Navigator.pop(context, duration);
  }
}



class CustomMinuteSecondPicker extends StatefulWidget {
  final String title;
  final Duration? duration;
  const CustomMinuteSecondPicker({
    super.key,
    this.title = "Time Length",
    this.duration,
  });

  @override
  State<CustomMinuteSecondPicker> createState() =>
      _CustomMinuteSecondPickerState();
}

class _CustomMinuteSecondPickerState extends State<CustomMinuteSecondPicker> {
  late int minutes;
  late int seconds;
  late FixedExtentScrollController minutesController;
  late FixedExtentScrollController secondsController;

  @override
  void initState() {
    minutes = widget.duration?.inMinutes ?? 1;
    seconds = widget.duration?.inSeconds.remainder(60) ?? 0;
    minutesController = FixedExtentScrollController(initialItem: minutes);
    secondsController = FixedExtentScrollController(initialItem: seconds);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height * 0.45;
    return SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(flex: 1, child: SizedBox()),
                Expanded(
                  flex: 5,
                  child: Text(
                    widget.title,
                    style: CustomTypography().titleLarge(),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: CustomColors.textNormalContent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: ListWheelScrollView.useDelegate(
                      controller: minutesController,
                      onSelectedItemChanged: (value) {
                        setState(() {
                          minutes = value;
                        });
                      },
                      physics: const FixedExtentScrollPhysics(),
                      perspective: 0.01,
                      diameterRatio: 1,
                      itemExtent: 50,
                      overAndUnderCenterOpacity: 0.3,
                      squeeze: 2,
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          return Minutes(mins: index);
                        },
                        childCount: 60,
                      ),
                    ),
                  ),
                ),
                Text("Mins",
                    style: CustomTypography()
                        .titleMedium(color: Colors.black)),

                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: ListWheelScrollView.useDelegate(
                      controller: secondsController,
                      onSelectedItemChanged: (value) {
                        setState(() {
                          seconds = value;
                        });
                      },
                      physics: const FixedExtentScrollPhysics(),
                      perspective: 0.01,
                      diameterRatio: 1,
                      itemExtent: 50,
                      overAndUnderCenterOpacity: 0.3,
                      squeeze: 2,
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          return Minutes(mins: index);
                        },
                        childCount: 60,
                      ),
                    ),
                  ),
                ),
                Text("Sec",
                    style: CustomTypography()
                        .titleMedium(color: Colors.black)),
              ],
            ),
            const SizedBox(height: 20),
            CustomElevatedButton(
              onClick: () => save(),
              text: "SAVE",
            ),
          ],
        ),
      ),
    );
  }

  void save() {
    Navigator.pop(context, Duration(minutes: minutes, seconds: seconds));
  }
}
