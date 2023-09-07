import 'package:flutter/material.dart';

import '../../../theme/custom_colors.dart';
import '../../../theme/custom_typography.dart';

class TestMicrophone extends StatefulWidget {
  const TestMicrophone({super.key});

  @override
  State<TestMicrophone> createState() => _TestMicrophoneState();
}

class _TestMicrophoneState extends State<TestMicrophone> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Your microphone access is fully set up. You can test the microphone before you start recording.",
          style: CustomTypography()
              .bodyMedium(color: CustomColors.textTertiaryContent),
        ),
        Row(
          children: [
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: CustomColors.productNormal),
              child: Text(
                "Test Microphone",
                style: CustomTypography()
                    .bodyMedium(color: CustomColors.textWhite),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
          ],
        )
      ],
    );
  }
}
