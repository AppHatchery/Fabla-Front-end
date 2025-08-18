import 'package:flutter/material.dart';

import '../../../../theme/components/textfields.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_icons.dart';
import '../../../../theme/custom_typography.dart';

class ParticipantName extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode node;
  final GlobalKey globalKey;
  const ParticipantName(
      {super.key,
      required this.controller,
      required this.node,
      required this.globalKey});

  @override
  State<ParticipantName> createState() => _ParticipantNameState();
}

class _ParticipantNameState extends State<ParticipantName> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter Your Preferred Name",
          style: CustomTypography().titleLarge(),
        ),
        const SizedBox(
          height: 12,
        ),
        CustomTextField(
          key: widget.globalKey,
          controller: widget.controller,
          focusNode: widget.node,
          hint: "Enter your preferred name",
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
