import 'package:audio_diaries_flutter/theme/components/textfields.dart';
import 'package:flutter/material.dart';

import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_icons.dart';
import '../../../../theme/custom_typography.dart';

class VerificationCodeTextField extends StatefulWidget {
  final String title;
  final String errorMessage;
  final String hint;
  final TextEditingController? controller;
  final TextInputType fieldType;
  final bool error;
  const VerificationCodeTextField(
      {super.key,
      required this.title,
      required this.errorMessage,
      required this.hint,
      this.controller,
      this.fieldType = TextInputType.number,
      this.error = false});

  @override
  State<VerificationCodeTextField> createState() =>
      _VerificationCodeTextFieldState();
}

class _VerificationCodeTextFieldState extends State<VerificationCodeTextField> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: CustomTypography().titleSmall(color: CustomColors.textWhite),
        ),
        const SizedBox(
          height: 6,
        ),
        CustomTextField(
          keyboardType: widget.fieldType,
          controller: widget.controller,
          error: widget.error,
          hint: widget.hint,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          filled: true,
          borderRadius: BorderRadius.circular(11),
          borderWidth: 0,
          suffix: IconButton(
              onPressed: () => widget.controller!.clear(),
              icon: const Icon(
                CustomIcons.cancel,
                size: 20,
              ),
              color: CustomColors.productBorderNormal),
        ),
        // const SizedBox(
        //   height: 12,
        // ),
        widget.error
            ? Container(
                width: width,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CustomColors.warningFill,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(CustomIcons.cancel,
                        size: 20, color: CustomColors.warningActive),
                    const SizedBox(
                      width: 10,
                    ),
                    Flexible(
                      child: Text(
                        widget.errorMessage,
                        style: CustomTypography()
                            .bodyLarge(color: CustomColors.warningActive),
                      ),
                    )
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
