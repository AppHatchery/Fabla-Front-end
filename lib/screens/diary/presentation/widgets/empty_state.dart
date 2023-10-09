import 'package:audio_diaries_flutter/theme/resources/strings.dart';
import 'package:flutter/material.dart';

import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

class BeforeStartWidget extends StatelessWidget {
  const BeforeStartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 47),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/start.png',
            height: 108,
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            'Your Fresh Start${Strings.champagne}',
            style: CustomTypography().titleLarge(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            "You're all set for a fresh start – no previous responses here!",
            style: CustomTypography()
                .bodyMedium(color: CustomColors.textTertiaryContent),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}