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
  final TextEditingController? controller;
  final bool error;
  final String? hint;
  final int maxLines;
  final bool isDisabled;
  final EdgeInsets padding;
  final bool filled;
  final Color fillColor;
  final BorderRadius borderRadius;
  final Color borderColor;
  final double borderWidth;
  final IconButton? suffix;
  const CustomTextField(
      {super.key,
      this.keyboardType = TextInputType.text,
      this.controller,
      this.error = false,
      this.hint,
      this.maxLines = 1,
      this.isDisabled = false,
      this.padding = const EdgeInsets.symmetric(horizontal: 16.5, vertical: 18),
      this.filled = false,
      this.fillColor = CustomColors.fillWhite,
      required this.borderRadius,
      this.borderColor = CustomColors.productBorderNormal,
      this.borderWidth = 2,
      this.suffix});

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      enabled: widget.isDisabled ? false : true,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      style: CustomTypography().titleSmall(),
      cursorColor: CustomColors.productNormal,
      decoration: InputDecoration(
        errorText: widget.error ? "" : null,
        filled: widget.filled,
        fillColor: widget.fillColor,
        suffixIcon: widget.suffix,
        border: OutlineInputBorder(
          borderRadius: widget.borderRadius,
          borderSide: BorderSide(
            color: widget.borderColor,
            width: widget.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: widget.borderRadius,
          borderSide: BorderSide(
            color: widget.borderColor,
            width: widget.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: widget.borderRadius,
          borderSide: BorderSide(
            color: CustomColors.productBorderActive,
            width: widget.borderWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: widget.borderRadius,
          borderSide: const BorderSide(
            color: CustomColors.warningNormal,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: widget.borderRadius,
          borderSide: const BorderSide(
            color: CustomColors.warningActive,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: widget.borderRadius,
          borderSide: BorderSide(
            color: CustomColors.productBorderNormal,
            width: widget.borderWidth,
          ),
        ),
        hintText: widget.hint,
        hintStyle: CustomTypography()
            .bodyLarge(color: CustomColors.textTertiaryContent),
        errorStyle:
            CustomTypography().bodyLarge(color: CustomColors.warningActive),
        contentPadding: widget.padding,
      ),
    );
  }
}
