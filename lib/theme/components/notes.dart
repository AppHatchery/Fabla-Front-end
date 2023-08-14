import 'package:flutter/material.dart';

import '../custom_colors.dart';
import '../custom_typography.dart';

class ResearchersNote extends StatelessWidget {
  const ResearchersNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CustomColors.productLightBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Research's Note:",
                style: CustomTypography().title(),
              ),
              const Icon(Icons.close_rounded)
            ],
          ),
          const SizedBox(height: 8),
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              "We recommend that you answer the questions as you see fit and relax and speak your mind.",
              style: CustomTypography().bodyLarge(),
            ),
          )
        ],
      ),
    );
  }
}
