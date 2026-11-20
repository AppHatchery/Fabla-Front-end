import 'dart:math' as math;

import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

import '../../core/usecases/font_scaler_detector_and_adjuster.dart';
import '../custom_colors.dart';

class CustomTimePicker extends StatefulWidget {
  final String title;
  final String? subtitle;
  final TimeOfDay? date;
  final VoidCallback? onDelete;
  final int minuteInterval;
  const CustomTimePicker(
      {super.key,
      this.title = "Reminder Time",
      this.subtitle,
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
    super.initState();
    final initial = widget.date ?? const TimeOfDay(hour: 0, minute: 0);
    // The minute wheel steps by minuteInterval: snap to it so the minute
    // that gets saved is the one the wheel shows.
    final minuteIndex = initial.minute ~/ widget.minuteInterval;
    _date = initial.replacing(minute: minuteIndex * widget.minuteInterval);
    hoursController = FixedExtentScrollController(
      initialItem: (_date.hour % 12) == 0 ? 11 : (_date.hour % 12) - 1,
    );
    minutesController = FixedExtentScrollController(
      initialItem: _date.minute,
    );
    minutesController = FixedExtentScrollController(initialItem: minuteIndex);
    periodController = FixedExtentScrollController(
      initialItem: (_date.hour >= 12) ? 1 : 0,
    );
  }

  @override
  void dispose() {
    hoursController.dispose();
    minutesController.dispose();
    periodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final itemExtent = _wheelItemExtent(context);
    return AdaptiveTextScaleScope(
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PickerHeader(title: widget.title),
              if (widget.subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Center(
                    child: Text(
                      widget.subtitle!,
                      style: CustomTypography().titleSmall(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  height: _wheelHeight(itemExtent),
                  width: _wheelAreaWidth(context, width),
                  child: Row(
                    children: [
                      Expanded(
                        child: _wheel(
                          controller: hoursController,
                          itemExtent: itemExtent,
                          childCount: 12,
                          onSelectedItemChanged: (value) => setState(() {
                            _date = _date.replacing(hour: value + 1);
                          }),
                          itemBuilder: (context, index) =>
                              Hours(hour: index + 1),
                        ),
                      ),
                      Expanded(
                        child: _wheel(
                          controller: minutesController,
                          itemExtent: itemExtent,
                          childCount: 60 ~/ widget.minuteInterval,
                          onSelectedItemChanged: (value) => setState(() {
                            _date = _date.replacing(
                              minute: value * widget.minuteInterval,
                            );
                          }),
                          itemBuilder: (context, index) =>
                              Minutes(mins: index * widget.minuteInterval),
                        ),
                      ),
                      Expanded(
                        child: _wheel(
                          controller: periodController,
                          itemExtent: itemExtent,
                          childCount: 2,
                          itemBuilder: (context, index) =>
                              Period(period: index == 0 ? "AM" : "PM"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomElevatedButton(onClick: () => save(), text: "SAVE"),
              const SizedBox(height: 24),
            ],
          ),
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

// ---------------------------------------------------------------------------
// Shared large-font layout for the pickers in this file.
// ---------------------------------------------------------------------------

/// Title centred over the picker with a close button on the right. The
/// close button's width is measured from the scaled icon, and an equal
/// spacer on the left keeps the title centred, so large text can't push
/// the button out of the row.
class _PickerHeader extends StatelessWidget {
  final String title;
  const _PickerHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    // IconButton = 24pt icon (scaled, applyTextScaling) + 8pt padding a side.
    final buttonWidth = math.max(
      kMinInteractiveDimension,
      MediaQuery.textScalerOf(context).scale(24) + 16,
    );
    return Row(
      children: [
        SizedBox(width: buttonWidth),
        Expanded(
          child: Text(
            title,
            style: CustomTypography().titleLarge(),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: buttonWidth,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              applyTextScaling: true,
              Icons.close,
              color: CustomColors.textNormalContent,
            ),
          ),
        ),
      ],
    );
  }
}

/// Height of one wheel row: the scaled digit line plus breathing room.
double _wheelItemExtent(BuildContext context) {
  final fontSize = CustomTypography().titleSmall().fontSize ?? 18;
  return math.max(
    50.0,
    getAdaptiveTextScaler(context).scale(fontSize) * 1.5 + 16,
  );
}

/// Wheel area height: about three and a half rows, never below the
/// original 200.
double _wheelHeight(double itemExtent) => math.max(200.0, itemExtent * 3.5);

/// Wheel area width: half the screen at normal text, widening with the text
/// scale up to the full content width (screen minus the 16pt side padding).
double _wheelAreaWidth(BuildContext context, double screenWidth) {
  final factor = getAdaptiveTextScaler(context).scale(1);
  return math.min(screenWidth - 32, screenWidth / 2 * factor);
}

Widget _wheel({
  required FixedExtentScrollController controller,
  required double itemExtent,
  required int childCount,
  required NullableIndexedWidgetBuilder itemBuilder,
  ValueChanged<int>? onSelectedItemChanged,
  double perspective = 0.003,
  double overAndUnderCenterOpacity = 0.5,
  double squeeze = 1,
}) {
  return ListWheelScrollView.useDelegate(
    controller: controller,
    onSelectedItemChanged: onSelectedItemChanged,
    physics: const FixedExtentScrollPhysics(),
    perspective: perspective,
    diameterRatio: 2,
    itemExtent: itemExtent,
    overAndUnderCenterOpacity: overAndUnderCenterOpacity,
    squeeze: squeeze,
    childDelegate: ListWheelChildBuilderDelegate(
      builder: itemBuilder,
      childCount: childCount,
    ),
  );
}

class Minutes extends StatelessWidget {
  final int mins;
  const Minutes({super.key, required this.mins});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        child: Center(
      child: Text(
        twoDigits(mins),
        style: CustomTypography().titleSmall(),
      ),
    ));
  }

  String twoDigits(int n) => n.toString().padLeft(2, "0");
}

class Hours extends StatelessWidget {
  final int hour;
  const Hours({super.key, required this.hour});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        child: Center(
      child: Text(
        hour.toString(),
        style: CustomTypography().titleSmall(),
      ),
    ));
  }
}

class HoursAndMinutes extends StatelessWidget {
  final double number;
  const HoursAndMinutes({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        child: Center(
      child: Text(
        number % 1 == 0 ? number.toInt().toString() : number.toStringAsFixed(1),
        style: CustomTypography().titleSmall(),
      ),
    ));
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
    super.initState();
    duration = widget.duration ?? const Duration(hours: 0, minutes: 0);
    hoursController = FixedExtentScrollController(
      initialItem: (duration.inMinutes / 30).round(),
    );
  }

  @override
  void dispose() {
    hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final itemExtent = _wheelItemExtent(context);
    return AdaptiveTextScaleScope(
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PickerHeader(title: widget.title),
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  height: _wheelHeight(itemExtent),
                  width: _wheelAreaWidth(context, width),
                  child: Row(
                    children: [
                      Text(
                        "Hours:",
                        style: CustomTypography().titleMedium(
                          color: CustomColors.textTertiaryContent,
                        ),
                      ),
                      Expanded(
                        child: _wheel(
                          controller: hoursController,
                          itemExtent: itemExtent,
                          childCount: 48,
                          overAndUnderCenterOpacity: 0.3,
                          onSelectedItemChanged: (value) {
                            final totalHours = value * 0.5;
                            final hours = totalHours.floor();
                            final minutes = ((totalHours - hours) * 60).round();
                            setState(() {
                              duration = Duration(
                                hours: hours,
                                minutes: minutes,
                              );
                            });
                          },
                          itemBuilder: (context, index) =>
                              HoursAndMinutes(number: 0.5 * index),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomElevatedButton(onClick: () => save(), text: "SAVE"),
            ],
          ),
        ),
      ),
    );
  }

  void save() {
    Navigator.pop(context, duration);
  }
}

// class _CustomTimeElapsedPickerState extends State<CustomTimeElapsedPicker> {
//   late Duration duration;
//   late FixedExtentScrollController hoursController;
//   late FixedExtentScrollController minutesController;

//   @override
//   void initState() {
//     duration = widget.duration ?? const Duration(hours: 0, minutes: 0);
//     hoursController = FixedExtentScrollController(
//       initialItem: duration.inHours,
//     );
//     minutesController = FixedExtentScrollController(
//       initialItem: duration.inMinutes.remainder(60),
//     );
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     return SizedBox(
//       width: width,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Expanded(flex: 1, child: SizedBox()),
//                 Expanded(
//                     flex: 5,
//                     child: Text(
//                       widget.title,
//                       style: CustomTypography().titleLarge(),
//                       textAlign: TextAlign.center,
//                     )),
//                 Expanded(
//                   flex: 1,
//                   child: Container(
//                       alignment: Alignment.centerRight,
//                       child: IconButton(
//                           onPressed: () => Navigator.pop(context),
//                           icon: const Icon(
//                             Icons.close,
//                             color: CustomColors.textNormalContent,
//                           ))),
//                 )
//               ],
//             ),
//             const SizedBox(
//               height: 32,
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(
//                   height: 200,
//                   width: width / 2,
//                   child: Center(
//                     child: Row(
//                       children: [
//                         Text("Hours:",
//                             style: CustomTypography().titleMedium(
//                                 color: CustomColors.textTertiaryContent)),
//                         Expanded(
//                           child: SizedBox(
//                             child: ListWheelScrollView.useDelegate(
//                               controller: hoursController,
//                               onSelectedItemChanged: (value) => setState(() {
//                                 duration = Duration(
//                                     hours: value,
//                                     minutes: duration.inMinutes.remainder(60));
//                               }),
//                               physics: const FixedExtentScrollPhysics(),
//                               perspective: 0.01,
//                               diameterRatio: 1,
//                               itemExtent: 50,
//                               overAndUnderCenterOpacity: 0.3,
//                               squeeze: 2,
//                               childDelegate: ListWheelChildBuilderDelegate(
//                                 builder: (context, index) {
//                                   return Hours(hour: index);
//                                 },
//                                 childCount: 24,
//                               ),
//                             ),
//                           ),
//                         ),
//                         Text("Mins:",
//                             style: CustomTypography().titleMedium(
//                                 color: CustomColors.textTertiaryContent)),
//                         Expanded(
//                           child: SizedBox(
//                             height: 200,
//                             width: 80,
//                             child: ListWheelScrollView.useDelegate(
//                               controller: minutesController,
//                               onSelectedItemChanged: (value) => setState(() {
//                                 duration = Duration(
//                                     hours: duration.inHours, minutes: value);
//                               }),
//                               physics: const FixedExtentScrollPhysics(),
//                               perspective: 0.01,
//                               diameterRatio: 1,
//                               itemExtent: 50,
//                               overAndUnderCenterOpacity: 0.3,
//                               squeeze: 2,
//                               childDelegate: ListWheelChildBuilderDelegate(
//                                 builder: (context, index) {
//                                   return Minutes(mins: index);
//                                 },
//                                 childCount: 60,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(
//               height: 24,
//             ),
//             CustomElevatedButton(onClick: () => save(), text: "SAVE"),
//           ],
//         ),
//       ),
//     );
//   }

//   void save() {
//     Navigator.pop(context, duration);
//   }
// }

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
    super.initState();
    minutes = widget.duration?.inMinutes ?? 1;
    seconds = widget.duration?.inSeconds.remainder(60) ?? 0;
    minutesController = FixedExtentScrollController(initialItem: minutes);
    secondsController = FixedExtentScrollController(initialItem: seconds);
  }

  @override
  void dispose() {
    minutesController.dispose();
    secondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final itemExtent = _wheelItemExtent(context);
    // The unit labels scale with text through the clamped MediaQuery below;
    // FittedBox shrinks them only if their column is too narrow.
    final labelStyle = CustomTypography().custom(
      color: CustomColors.textNormalContent,
      fontSize: 18,
      fontWeight: FontWeight.w400,
    );

    // Sized to its content (the sheet is scroll-controlled) and scrollable,
    // so a two-line title and a tall SAVE button never squeeze the wheels.
    return AdaptiveTextScaleScope(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: keyboardInset + 24,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PickerHeader(title: widget.title),
              const SizedBox(height: 24),
              SizedBox(
                height: _wheelHeight(itemExtent),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _wheel(
                        controller: minutesController,
                        itemExtent: itemExtent,
                        childCount: 60,
                        perspective: 0.01,
                        overAndUnderCenterOpacity: 0.3,
                        squeeze: 1.2,
                        onSelectedItemChanged: (value) =>
                            setState(() => minutes = value),
                        itemBuilder: (context, index) => Minutes(mins: index),
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("min", style: labelStyle),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _wheel(
                        controller: secondsController,
                        itemExtent: itemExtent,
                        childCount: 60,
                        perspective: 0.01,
                        overAndUnderCenterOpacity: 0.3,
                        squeeze: 1.2,
                        onSelectedItemChanged: (value) =>
                            setState(() => seconds = value),
                        itemBuilder: (context, index) => Minutes(mins: index),
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("sec", style: labelStyle),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomElevatedButton(onClick: save, text: "SAVE"),
            ],
          ),
        ),
      ),
    );
  }

  void save() {
    Navigator.pop(context, Duration(minutes: minutes, seconds: seconds));
  }
}
