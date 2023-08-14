import 'package:flutter/material.dart';

import '../custom_typography.dart';

/// Custom checkbox.
///
/// [value] is the current value of the checkbox.
///
/// [label] is the text that will be displayed.
///
/// A callback function [onChanged] is called when the checkbox is selected.
class CustomCheckbox extends StatefulWidget {
  final bool value;
  final String? label;
  final ValueChanged<bool?>? onChanged;
  const CustomCheckbox(
      {super.key,
      required this.value,
      required this.label,
      required this.onChanged});

  @override
  State<CustomCheckbox> createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> {
  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: widget.value,
      onChanged: widget.onChanged,
      title: Text(widget.label.toString(), style: CustomTypography().button()),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.black,
      visualDensity: const VisualDensity(vertical: -4),
    );
  }
}
