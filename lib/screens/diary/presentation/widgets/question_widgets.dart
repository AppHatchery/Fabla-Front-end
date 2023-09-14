import 'package:flutter/material.dart';

import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

class Trial extends StatelessWidget {
  const Trial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.fillDisabled,
      appBar: AppBar(
          title: const Text(
        "Trial",
      )),
      body: const Column(children: [
        // Padding(
        //   padding: EdgeInsets.all(12.0),
        //   child: CheckboxQuestionCard(
        //     answers: [
        //       "Does this feel fake",
        //       "wish we could turn back time",
        //       "I am lost in this world,I am lost in this world,"
        //     ],
        //   ),
        // ),
        SizedBox(
          height: 12,
        ),
        TextQuestionCard(),
        // SliderQuestionCard(
        //   scaleMaxText: "Extremely pleasant",
        //   scaleMinText: "Extremely unpleasant",
        // ),
        SizedBox(
          height: 12,
        ),
        RadioQuestionCard(
          answers: ["0", "1", "2 or more"],
        )
      ]),
    );
  }
}

class SliderQuestionCard extends StatefulWidget {
  final String scaleMinText;
  final String scaleMaxText;
  const SliderQuestionCard(
      {super.key, required this.scaleMinText, required this.scaleMaxText});

  @override
  State<SliderQuestionCard> createState() => _SliderQuestionCardState();
}

class _SliderQuestionCardState extends State<SliderQuestionCard> {
  double _currentSliderValue = 0;
  double _maxSliderValue = 10;
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
            Text(_currentSliderValue.round().toString()),
            Expanded(
              child: Slider(
                value: _currentSliderValue,
                max: _maxSliderValue,
                divisions: 10,
                label: _currentSliderValue.round().toString(),

                onChanged: (double value) {
                  setState(() {
                    _currentSliderValue = value;
                  });
                },
                activeColor: CustomColors.productNormalActive,
                inactiveColor: CustomColors.newBlue,
                //overlayColor:CustomColors.newBlue,
              ),
            ),
            Text(_maxSliderValue.round().toString()),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 87,
              child: Text(
                widget.scaleMinText,
                textAlign: TextAlign.start,
              ),
            ),
            SizedBox(
              width: 87,
              child: Text(
                widget.scaleMaxText,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        )
      ]),
    );
  }
}

class CheckboxQuestionCard extends StatefulWidget {
  final List<String> answers;
  const CheckboxQuestionCard({super.key, required this.answers});

  @override
  State<CheckboxQuestionCard> createState() => _CheckboxQuestionCardState();
}

class _CheckboxQuestionCardState extends State<CheckboxQuestionCard> {
  List<bool> _selected = [];

  @override
  void initState() {
    super.initState();
    _selected = List<bool>.filled(widget.answers.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: widget.answers.length,
        itemBuilder: (context, index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 3.0),
                decoration: BoxDecoration(
                    color: CustomColors.productLightPrimaryNormalWhite,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(
                        color: CustomColors.productBorderNormal, width: 2)),
                child: CheckboxListTile(
                  title: Text(
                    widget.answers[index],
                    style: CustomTypography()
                        .button(color: CustomColors.productNormalActive),
                  ),
                  checkColor: CustomColors.productLightPrimaryNormalWhite,
                  fillColor: MaterialStateProperty.all(
                      CustomColors.productNormalActive),
                  onChanged: (value) {
                    setState(() {
                      _selected[index] = value!;
                    });
                  },
                  value: _selected[index],
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
            ],
          );
        });
  }
}

class RadioQuestionCard extends StatefulWidget {
  final List<String> answers;
  const RadioQuestionCard({super.key, required this.answers});

  @override
  State<RadioQuestionCard> createState() => _RadioQuestionCardState();
}

class _RadioQuestionCardState extends State<RadioQuestionCard> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: widget.answers.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 3.0),
                decoration: BoxDecoration(
                    color: CustomColors.productLightPrimaryNormalWhite,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(
                        color: CustomColors.productBorderNormal, width: 2)),
                child: RadioListTile(
                  title: Text(
                    widget.answers[index],
                    style: CustomTypography()
                        .button(color: CustomColors.productNormalActive),
                  ),
                  fillColor: MaterialStateProperty.all(
                      CustomColors.productNormalActive),
                  onChanged: (value) {
                    setState(() {
                      _selected = index;
                    });
                  },
                  value: index,
                  groupValue: _selected,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
            ],
          );
        });
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
