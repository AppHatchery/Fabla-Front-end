import 'package:audio_diaries_flutter/core/usecases/font_scaler_detector_and_adjuster.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

import '../../../../theme/components/empty_state_layout.dart';

class FreeDayWidget extends StatelessWidget {
  const FreeDayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateLayout(
      imageAsset: 'assets/images/empty-box.png',
      imageHeight: getAdaptiveTextScaler(context).scale(108),
      title: 'No Surveys Scheduled Today',
      titleStyle: CustomTypography().titleLarge(),
      message: "We’ll notify you when your next one is available.",
    );
  }
}

class EndStateWidget extends StatelessWidget {
  const EndStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateLayout(
      imageAsset: 'assets/images/complete.png',
      title: 'Research Journey End',
      titleStyle: CustomTypography().titleMedium(),
      message:
          "No entries - the study reaches its conclusion. Thank you for being a part of this journey!",
    );
  }
}

class DayComplete extends StatelessWidget {
  const DayComplete({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateLayout(
      imageAsset: 'assets/images/complete.png',
      title: "That's it for today",
      titleStyle: CustomTypography().titleMedium(),
      message:
          "Check your study calendar to see when your next entries are available",
    );
  }
}
