import 'package:flutter/material.dart';

import '../../../../theme/components/textfields.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_icons.dart';
import '../../../../theme/custom_typography.dart';

class ParticipantName extends StatefulWidget {
  final TextEditingController controller;
  const ParticipantName({super.key, required this.controller});

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
          "Nickname",
          style: CustomTypography().titleLarge(),
        ),
        const SizedBox(
          height: 12,
        ),
        CustomTextField(
          controller: widget.controller,
          hint: "Enter a nickname",
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          filled: true,
          borderRadius: BorderRadius.circular(11),
          borderWidth: 2,
          suffix: IconButton(
            onPressed: () => widget.controller.clear(),
            icon: const Icon(CustomIcons.cancel, size: 20,),
            color: CustomColors.productBorderNormal,
          ),
        )
      ],
    );
  }
}
