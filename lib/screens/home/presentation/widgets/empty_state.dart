import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

import '../../../../theme/custom_colors.dart';

class FreeDayWidget extends StatelessWidget {
  const FreeDayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 47),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty-box.png',
            height: 108,
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            'This is a Free Day',
            style: CustomTypography().titleLarge(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            "It's a blank slate for today on your study calendar – embrace this open day!",
            style: CustomTypography()
                .bodyMedium(color: CustomColors.textTertiaryContent),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class EndStateWidget extends StatelessWidget {
  const EndStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 47),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/complete.png',
            height: 108,
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            'Research Journey End',
            style: CustomTypography().titleMedium(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            "No tasks - the study reaches its conclusion. Thank you for being a part of this journey!",
            style: CustomTypography()
                .bodyMedium(color: CustomColors.textTertiaryContent),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class DayComplete extends StatelessWidget {
  const DayComplete({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 47),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/complete.png',
            height: 108,
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            "That's it for today",
            style: CustomTypography().titleMedium(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            "Check your study calendar to see when your next tasks are due",
            style: CustomTypography()
                .bodyMedium(color: CustomColors.textTertiaryContent),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
