import 'package:flutter/material.dart';

import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

///These widgets are being used in the QuestionPage class
///They are used to diplay tbe answer options for each question
///whether slider option, multiple questions or radio questions

class SliderQuestionCard extends StatefulWidget {
  final double value;
  final String? scaleMinText;
  final String? scaleMaxText;
  final int scaleMin;
  final int scaleMax;
  final ValueChanged<double>? onSliderValueChanged;
  const SliderQuestionCard({
    super.key,
    required this.value,
    required this.scaleMinText,
    required this.scaleMaxText,
    this.onSliderValueChanged,
    required this.scaleMin,
    required this.scaleMax,
  });

  @override
  State<SliderQuestionCard> createState() => _SliderQuestionCardState();
}

class _SliderQuestionCardState extends State<SliderQuestionCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
          color: CustomColors.productLightPrimaryNormalWhite,
          borderRadius: BorderRadius.circular(14.0)),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.scaleMin.toString()),
            Expanded(
              child: Slider(
                value: widget.value,
                min: widget.scaleMin.toDouble(),
                max: widget.scaleMax.toDouble(),
                divisions: widget.scaleMax - widget.scaleMin,
                label: widget.value.round().toString(),
                onChanged: (double value) {
                  if (widget.onSliderValueChanged != null) {
                    widget.onSliderValueChanged!(value);
                  }
                },
                activeColor: CustomColors.productNormalActive,
                inactiveColor: CustomColors.newBlue,
                //overlayColor:CustomColors.newBlue,
              ),
            ),
            Text(widget.scaleMax.toString()),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 87,
              child: Text(
                widget.scaleMinText!,
                textAlign: TextAlign.start,
              ),
            ),
            SizedBox(
              width: 87,
              child: Text(
                widget.scaleMaxText!,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        )
      ]),
    );
  }
}

class MultipleQuestion extends StatefulWidget {
  final List<String> options;
  final List<String>? selected;
  final ValueChanged<List<String>>? onChanged;

  const MultipleQuestion(
      {super.key,
      required this.options,
      required this.selected,
      required this.onChanged});

  @override
  State<MultipleQuestion> createState() => _MultipleQuestionState();
}

class _MultipleQuestionState extends State<MultipleQuestion> {
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
                  color: CustomColors.productLightPrimaryNormalWhite,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                      color: CustomColors.productBorderNormal, width: 2)),
              child: CheckboxListTile(
                title: Text(
                  widget.options[index],
                  style: CustomTypography()
                      .button(color: CustomColors.productNormalActive),
                ),
                checkColor: CustomColors.productLightPrimaryNormalWhite,
                fillColor:
                    MaterialStateProperty.all(CustomColors.productNormalActive),
                controlAffinity: ListTileControlAffinity.leading,
                value: selectedOptions.contains(widget.options[index]),
                onChanged: (value) {
                  if (value!) {
                    selectedOptions.add(widget.options[index]);
                  } else {
                    selectedOptions.remove(widget.options[index]);
                  }

                  setState(() {
                    widget.onChanged!(selectedOptions);
                  });
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

class RadioQuestion extends StatefulWidget {
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const RadioQuestion(
      {super.key, required this.value,required this.options, required this.onChanged});

  @override
  State<RadioQuestion> createState() => _RadioQuestionState();
}

class _RadioQuestionState extends State<RadioQuestion> {

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.options.length,
      itemBuilder: (context, index) {
        return Column(children: [
          Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 3.0),
              decoration: BoxDecoration(
                  color: CustomColors.productLightPrimaryNormalWhite,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                      color: CustomColors.productBorderNormal, width: 2)),
              child: RadioListTile<String>(
                title: Text(
                  widget.options[index],
                  style: CustomTypography()
                      .button(color: CustomColors.productNormalActive),
                ),
                fillColor:
                    MaterialStateProperty.all(CustomColors.productNormalActive),
                controlAffinity: ListTileControlAffinity.leading,
                value: widget.options[index],
                groupValue: widget.value,
                onChanged: (String? value) {
                  widget.onChanged(value);
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

class TextQuestionCard extends StatefulWidget {
  const TextQuestionCard({super.key});

  @override
  State<TextQuestionCard> createState() => _TextQuestionCardState();
}

class _TextQuestionCardState extends State<TextQuestionCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0)),
        TextField(
          decoration: InputDecoration(
            hintText: 'Type your message',
            hintStyle: CustomTypography()
                .button(color: CustomColors.textTertiaryContent),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CustomColors.productBorderNormal),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CustomColors.productBorderNormal),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: CustomColors.productBorderActive),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
          maxLines: null,
        )
      ],
    );
  }
}
