import 'package:flutter/material.dart';

import '../../../../theme/components/empty_state_layout.dart';
import '../../../../theme/custom_typography.dart';

class BeforeStartWidget extends StatelessWidget {
  const BeforeStartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateLayout(
      imageAsset: 'assets/images/start.png',
      title: 'No Responses Recorded Yet',
      titleStyle: CustomTypography().titleLarge(),
      message:
          "Your past responses will be available here as you progress through the study.",
    );
  }
}
