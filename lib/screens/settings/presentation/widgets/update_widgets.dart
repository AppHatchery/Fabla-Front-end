import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/dynamic_widget.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/components/calendar.dart';
import 'package:audio_diaries_flutter/theme/components/textfields.dart';
import 'package:audio_diaries_flutter/theme/components/time_picker.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

class UpdateTimePicker extends StatefulWidget {
  final String title;
  final String subtitle;
  final int index;
  final TimeOfDay? date;
  final int minuteInterval;
  const UpdateTimePicker(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.index,
      this.date,
      this.minuteInterval = 5});

  @override
  State<UpdateTimePicker> createState() => _UpdateTimePickerState();
}

class _UpdateTimePickerState extends State<UpdateTimePicker> {
  late TimeOfDay _date;
  late FixedExtentScrollController hoursController;
  late FixedExtentScrollController minutesController;
  late FixedExtentScrollController periodController;

  late MaterialLocalizations localizations;

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
    localizations = MaterialLocalizations.of(context);
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
                Expanded(
                    flex: 1,
                    child: Text(
                      "Question ${widget.index}",
                      style: CustomTypography().bodyLarge(),
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
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: CustomTypography().titleLarge(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.subtitle,
                        style: CustomTypography().bodyMedium(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
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
            CustomElevatedButton(onClick: () => save(), text: "Update"),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextButton(
                    onClick: () => Navigator.pop(context),
                    text: "Cancel",
                    textColor: CustomColors.warningActive,
                  ),
                ),
              ],
            )
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

    Navigator.pop(context,
        localizations.formatTimeOfDay(_date, alwaysUse24HourFormat: true));
  }
}

class UpdateRadioOptions extends StatefulWidget {
  final String title;
  final String subtitle;
  final int index;
  final String selected;
  final List<Option> options;
  const UpdateRadioOptions(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.index,
      required this.selected,
      required this.options});

  @override
  State<UpdateRadioOptions> createState() => _UpdateRadioOptionsState();
}

class _UpdateRadioOptionsState extends State<UpdateRadioOptions> {
  String answer = "";

  @override
  initState() {
    answer = widget.selected;
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
                Expanded(
                    flex: 1,
                    child: Text(
                      "Question ${widget.index}",
                      style: CustomTypography().bodyLarge(),
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
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: CustomTypography().titleLarge(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.subtitle,
                        style: CustomTypography().bodyMedium(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 32,
            ),
            CustomRadioQuestion(
              selected: answer,
              options: widget.options,
              onChanged: (value) => {
                if (mounted)
                  {
                    setState(() {
                      answer = value!;
                    })
                  }
              },
            ),
            const SizedBox(
              height: 24,
            ),
            CustomElevatedButton(onClick: () => save(), text: "Update"),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextButton(
                    onClick: () => Navigator.pop(context),
                    text: "Cancel",
                    textColor: CustomColors.warningActive,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  save() {
    if (mounted) {
      Navigator.pop(context, answer);
    }
  }
}

class UpdateMultipleOptions extends StatefulWidget {
  final String title;
  final String subtitle;
  final int index;
  final List<String> selected;
  final List<Option> options;
  const UpdateMultipleOptions(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.index,
      required this.selected,
      required this.options});

  @override
  State<UpdateMultipleOptions> createState() => _UpdateMultipleOptionsState();
}

class _UpdateMultipleOptionsState extends State<UpdateMultipleOptions> {
  String answer = "";
  @override
  initState() {
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
                Expanded(
                    flex: 1,
                    child: Text(
                      "Question ${widget.index}",
                      style: CustomTypography().bodyLarge(),
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
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: CustomTypography().titleLarge(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.subtitle,
                        style: CustomTypography().bodyMedium(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 32,
            ),
            CustomMultipleQuestion(
              selected: widget.selected,
              options: widget.options,
              onChanged: (value) {
                setState(() {
                  answer = value.toString();
                });
              },
            ),
            const SizedBox(
              height: 24,
            ),
            CustomElevatedButton(onClick: () => save(), text: "Update"),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextButton(
                    onClick: () => Navigator.pop(context),
                    text: "Cancel",
                    textColor: CustomColors.warningActive,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  save() {
    if (mounted) {
      Navigator.pop(context, answer);
    }
  }
}

class UpdateSliderOption extends StatefulWidget {
  final String title;
  final String subtitle;
  final int index;
  final int min;
  final int max;
  final String minLabel;
  final String maxLabel;
  final String value;
  final int defaultValue;
  const UpdateSliderOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.index,
    required this.min,
    required this.max,
    required this.minLabel,
    required this.maxLabel,
    required this.value,
    required this.defaultValue,
  });

  @override
  State<UpdateSliderOption> createState() => _UpdateSliderOptionState();
}

class _UpdateSliderOptionState extends State<UpdateSliderOption> {
  double value = 0;

  @override
  void initState() {
    value = double.parse(widget.value);
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
                Expanded(
                    flex: 1,
                    child: Text(
                      "Question ${widget.index}",
                      style: CustomTypography().bodyLarge(),
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
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: CustomTypography().titleLarge(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.subtitle,
                        style: CustomTypography().bodyMedium(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 32,
            ),
            OnBoardingSlider(
                scaleMinText: widget.minLabel,
                scaleMaxText: widget.maxLabel,
                scaleMin: widget.min,
                scaleMax: widget.max,
                value: value,
                defaultValue: widget.defaultValue,
                onChanged: (_value) {
                  setState(() {
                    value = _value;
                  });
                }),
            const SizedBox(
              height: 24,
            ),
            CustomElevatedButton(onClick: () => save(), text: "Update"),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextButton(
                    onClick: () => Navigator.pop(context),
                    text: "Cancel",
                    textColor: CustomColors.warningActive,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  save() {
    if (mounted) {
      Navigator.pop(context, value.toString());
    }
  }
}

class UpdateTextOption extends StatefulWidget {
  final String title;
  final String subtitle;
  final int index;
  final String? answer;
  const UpdateTextOption(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.index,
      this.answer});

  @override
  State<UpdateTextOption> createState() => _UpdateTextOptionState();
}

class _UpdateTextOptionState extends State<UpdateTextOption> {
  late TextEditingController controller;

  @override
  void initState() {
    controller = TextEditingController(text: widget.answer);
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
                Expanded(
                    flex: 1,
                    child: Text(
                      "Question ${widget.index}",
                      style: CustomTypography().bodyLarge(),
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
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: CustomTypography().titleLarge(),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.subtitle,
                        style: CustomTypography().bodyMedium(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 32,
            ),
            Text(
              "Answer",
              style: CustomTypography().titleSmallCustom(),
            ),
            const SizedBox(
              height: 12,
            ),
            CustomTextField(
                controller: controller,
                borderRadius: BorderRadius.circular(12)),
            const SizedBox(
              height: 24,
            ),
            CustomElevatedButton(onClick: () => save(), text: "Update"),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextButton(
                    onClick: () => Navigator.pop(context),
                    text: "Cancel",
                    textColor: CustomColors.warningActive,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  save() {
    if (mounted) {
      Navigator.pop(context, controller.text);
    }
  }
}

class UpdateDateOption extends StatefulWidget {
  final String title;
  final String subtitle;
  final int index;
  final DateTime date;
  const UpdateDateOption(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.index,
      required this.date});

  @override
  State<UpdateDateOption> createState() => _UpdateDateOptionState();
}

class _UpdateDateOptionState extends State<UpdateDateOption> {
  late DateTime date;

  @override
  void initState() {
    date = widget.date;
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
                Expanded(
                    flex: 1,
                    child: Text(
                      "Question ${widget.index}",
                      style: CustomTypography().bodyLarge(),
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
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: CustomTypography().titleLarge(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.subtitle,
                        style: CustomTypography().bodyMedium(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 32,
            ),
            CustomDatePicker(
              date: date,
              onSelect: (value) => setState(() {
                date = value;
              }),
            ),
            const SizedBox(
              height: 24,
            ),
            CustomElevatedButton(onClick: () => save(), text: "Update"),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Expanded(
                  child: CustomTextButton(
                    onClick: () => Navigator.pop(context),
                    text: "Cancel",
                    textColor: CustomColors.warningActive,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  save() {
    if (mounted) {
      Navigator.pop(context, formatDateOnly(date));
    }
  }
}
