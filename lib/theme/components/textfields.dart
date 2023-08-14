import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

/// Custom Text Field.
///
/// [keyboardType] is the type of keyboard to use for editing the text.
///
/// [hint] is the text that will be displayed when the text field is empty.
///
/// [maxLines] is the maximum number of lines for the text to span.
///
/// [isDisabled] is a boolean that determines if the text field is disabled.
class CustomTextField extends StatefulWidget {
  final TextInputType? keyboardType;
  final String? hint;
  final int maxLines;
  final bool isDisabled;
  const CustomTextField(
      {super.key,
      this.keyboardType = TextInputType.text,
      this.hint,
      this.maxLines = 1,
      this.isDisabled = false});

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController controller;

  @override
  void initState() {
    controller = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: widget.isDisabled ? false : true,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      style: CustomTypography().titleSmall(),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: CustomColors.productBorderNormal,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: CustomColors.productBorderNormal,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: CustomColors.productBorderActive,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: CustomColors.warningNormal,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: CustomColors.warningActive,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: CustomColors.productBorderNormal,
            width: 2,
          ),
        ),
        hintText: widget.hint,
        hintStyle: CustomTypography().titleSmall(color: CustomColors.textTertiaryContent),
        errorStyle: CustomTypography().titleSmall(color: CustomColors.warningActive),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16.5,
        ),
      ),
    );
  }
}
