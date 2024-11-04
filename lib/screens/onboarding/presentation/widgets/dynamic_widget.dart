import 'dart:math';

import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/question_widgets.dart';
import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';
import 'package:audio_diaries_flutter/theme/components/textfields.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_icons.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

class OnBoardingTextField extends StatefulWidget {
  final String subtitle;
  final TextEditingController controller;
  const OnBoardingTextField(
      {super.key, required this.subtitle, required this.controller});

  @override
  State<OnBoardingTextField> createState() => _OnBoardingTextFieldState();
}

class _OnBoardingTextFieldState extends State<OnBoardingTextField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.subtitle,
          style: CustomTypography().titleLarge(),
        ),
        const SizedBox(
          height: 12,
        ),
        CustomTextField(
          controller: widget.controller,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          filled: true,
          borderRadius: BorderRadius.circular(11),
          borderWidth: 2,
          suffix: IconButton(
            onPressed: () => widget.controller.clear(),
            icon: const Icon(
              CustomIcons.cancel,
              size: 20,
            ),
            color: CustomColors.productBorderNormal,
          ),
        )
      ],
    );
  }
}

class OnBoardingRadioOptions extends StatefulWidget {
  final String subtitle;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  const OnBoardingRadioOptions(
      {super.key,
      required this.subtitle,
      required this.options,
      required this.value,
      required this.onChanged});

  @override
  State<OnBoardingRadioOptions> createState() => _OnBoardingRadioOptionsState();
}

class _OnBoardingRadioOptionsState extends State<OnBoardingRadioOptions> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.subtitle,
          style: CustomTypography().titleLarge(),
        ),
        const SizedBox(
          height: 12,
        ),
        RadioQuestion(
          value: widget.value,
          options: widget.options,
          onChanged: (value) => widget.onChanged(value),
        )
      ],
    );
  }
}

class OnBoardingMultipleOption extends StatefulWidget {
  final String subtitle;
  final List<Option> options;
  final List<String>? selected;
  final ValueChanged<String?> onChanged;
  const OnBoardingMultipleOption(
      {super.key,
      required this.subtitle,
      required this.options,
      required this.selected,
      required this.onChanged});

  @override
  State<OnBoardingMultipleOption> createState() =>
      _OnBoardingMultipleOptionState();
}

class _OnBoardingMultipleOptionState extends State<OnBoardingMultipleOption> {
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).textScaleFactor;
    double padding = max(((scale - 1.0) * 10).ceil() * 20, 20.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.subtitle,
          style: CustomTypography().titleLarge(),
        ),
        const SizedBox(
          height: 12,
        ),
        Padding(
          padding: EdgeInsets.only(bottom: padding),
          child: CustomMultipleQuestion(
            selected: widget.selected ,
            options: widget.options,
            onChanged: (value) {
              widget.onChanged(value.toString());
            },
          ),
        )
      ],
    );
  }
}


class CustomMultipleQuestion extends StatefulWidget {
  final List<Option> options;
  final List<String>? selected;
  final ValueChanged<List<String>>? onChanged;
  final bool disabled;

  const CustomMultipleQuestion(
      {super.key,
      required this.options,
      required this.selected,
      required this.onChanged,
      this.disabled = false});

  @override
  State<CustomMultipleQuestion> createState() => _CustomMultipleQuestion();
}

class _CustomMultipleQuestion extends State<CustomMultipleQuestion> {
  late List<String> selectedOptions;

  @override
  void initState() {
    selectedOptions = widget.selected ?? [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.options.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
              decoration: BoxDecoration(
                  color: selectedOptions.contains(widget.options[index].value) &&
                          !widget.disabled
                      ? CustomColors.productLightBackground
                      : CustomColors.productLightPrimaryNormalWhite,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                      color: selectedOptions.contains(widget.options[index].value) &&
                              !widget.disabled
                          ? CustomColors.productBorderActive
                          : CustomColors.productBorderNormal,
                      width: 2)),
              child: CheckboxListTile(
                title: Text(
                  widget.options[index].title,
                  style: CustomTypography().button(
                      color: selectedOptions.contains(widget.options[index].value) &&
                              !widget.disabled
                          ? CustomColors.productNormalActive
                          : Colors.black),
                ),
                checkColor: CustomColors.productLightPrimaryNormalWhite,
                fillColor: selectedOptions.contains(widget.options[index].value) &&
                        !widget.disabled
                    ? WidgetStateProperty.all(
                        CustomColors.productNormalActive)
                    : selectedOptions.contains(widget.options[index].value)
                        ? WidgetStateProperty.all(
                            CustomColors.textTertiaryContent)
                        : null,
                controlAffinity: ListTileControlAffinity.leading,
                value: selectedOptions.contains(widget.options[index].value),
                onChanged: (value) {
                  print("value: $value");
                  if (!widget.disabled) {
                    if (value!) {
                      selectedOptions.add(widget.options[index].value.toString());
                    } else {
                      selectedOptions.remove(widget.options[index].value.toString());
                    }

                    setState(() {
                      widget.onChanged!(selectedOptions);
                    });
                  }
                },
              )),
          const SizedBox(
            height: 12,
          ),
        ]);
      },
    );
  }
}



class OnBoardingSlider extends StatefulWidget {
  final String scaleMinText;
  final String scaleMaxText;
  final int scaleMin;
  final int scaleMax;
  final double? value;
  final int defaultValue;
  final ValueChanged<double> onChanged;
  const OnBoardingSlider(
      {super.key,
      required this.scaleMinText,
      required this.scaleMaxText,
      required this.scaleMin,
      required this.scaleMax,
      required this.value,
      required this.defaultValue, required this.onChanged});

  @override
  State<OnBoardingSlider> createState() => _OnBoardingSliderState();
}

class _OnBoardingSliderState extends State<OnBoardingSlider> {
  late double value;

  @override
  void initState() {
    value = widget.value ?? widget.defaultValue.toDouble();
    print("value: $value | defaultValue: ${widget.defaultValue} | scaleMin: ${widget.scaleMin} | scaleMax: ${widget.scaleMax}");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SliderQuestionCard(
        value: value,
        scaleMinText: widget.scaleMinText,
        scaleMaxText: widget.scaleMaxText,
        scaleMin: widget.scaleMin,
        scaleMax: widget.scaleMax,
        isSliderEnabled: true,
        onSliderValueChanged: (value) {
          setState(() {
            this.value = value;
            print("value: $value");
            widget.onChanged(value);
          });
        });
  }
}
