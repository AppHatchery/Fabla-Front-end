import 'package:flutter/material.dart';

import '../custom_colors.dart';
import '../custom_typography.dart';

/// Custom option with elevation.
///
/// [value] is the current value of the option.
///
/// [label] is the text that will be displayed.
///
/// A callback function [onChange] is called when the option is selected.
class CustomOption extends StatefulWidget {
  final bool? value;
  final String? label;
  final ValueChanged<bool?>? onChange;
  const CustomOption(
      {super.key,
      required this.value,
      required this.label,
      required this.onChange});

  @override
  State<CustomOption> createState() => _CustomOptionState();
}

class _CustomOptionState extends State<CustomOption> {
  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: widget.value!
            ? CustomColors.productLightBackground
            : CustomColors.fillWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: widget.value!
                ? CustomColors.productBorderActive
                : CustomColors.productBorderNormal,
            width: 2),
        boxShadow: [
          BoxShadow(
            color: CustomColors.productBorderNormal,
            blurRadius: 0,
            offset: Offset(0, widget.value! ? 0 : 3.5),
          ),
        ],
        shape: BoxShape.rectangle,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (widget.onChange != null) {
            var newValue = !widget.value!;
            widget.onChange!(newValue);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 18.0),
          child: Center(
              child: Text(
            widget.label.toString(),
            style: CustomTypography()
                .button(color: CustomColors.productNormalActive),
          )),
        ),
      ),
    );
  }
}

/// Custom option with no elevation.
///
/// [value] is the current value of the option.
///
/// [label] is the text that will be displayed.
///
/// A callback function [onChange] is called when the option is selected.
class CustomTextOption extends StatefulWidget {
  final bool? value;
  final String? label;
  final ValueChanged<bool?>? onChange;
  const CustomTextOption(
      {super.key,
      required this.value,
      required this.label,
      required this.onChange});

  @override
  State<CustomTextOption> createState() => _CustomTextOptionState();
}

class _CustomTextOptionState extends State<CustomTextOption> {
  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: widget.value!
            ? CustomColors.productLightBackground
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: widget.value!
                ? CustomColors.productBorderActive
                : Colors.transparent,
            width: 2),
        shape: BoxShape.rectangle,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (widget.onChange != null) {
            var newValue = !widget.value!;
            widget.onChange!(newValue);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 18.0),
          child: Center(
              child: Text(
            widget.label.toString(),
            style: CustomTypography()
                .button(color: CustomColors.productNormalActive),
          )),
        ),
      ),
    );
  }
}

/// Combination of CustomOption and CustomTextOption
///
/// [options] is a list of strings that will be displayed as options.
///
/// A callback function [onChange] can be added to be called when an option is selected.
class CustomOptionGroup extends StatefulWidget {
  final List<String> options;
  final Function(String) onSelect;
  const CustomOptionGroup({super.key, required this.options, required this.onSelect});

  @override
  State<CustomOptionGroup> createState() => _CustomOptionGroupState();
}

class _CustomOptionGroupState extends State<CustomOptionGroup> {
  int? selectedIndex;
  @override
  Widget build(BuildContext context) {
    return Column(
        children: widget.options.asMap().entries.map((option) {
      final index = option.key;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: option.value.toString() == "I DON'T WANT TO ANSWER THIS QUESTION"
            ? CustomTextOption(
                value: selectedIndex == index,
                label: option.value.toString(),
                onChange: (newValue) {
                  setState(() {
                    if (newValue == true) {
                      selectedIndex = index;
                    } else {
                      selectedIndex = null;
                    }
                  });
                },
              )
            : CustomOption(
                value: selectedIndex == index,
                label: option.value.toString(),
                onChange: (newValue) {
                  setState(() {
                    if (newValue == true) {
                      selectedIndex = index;
                      widget.onSelect(option.value.toString()); // Call the callback function
                    } else {
                      selectedIndex = null;
                    }
                  });
                },
              ),
      );
    }).toList());
  }
}
