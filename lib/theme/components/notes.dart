import 'package:flutter/material.dart';

import '../custom_colors.dart';
import '../custom_typography.dart';

class ResearchersNote extends StatelessWidget {
  final String? note;
  final ValueChanged<bool> onDismissed;
  const ResearchersNote(
      {super.key, required this.note, required this.onDismissed});

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
              GestureDetector(
                  onTap: () => onDismissed(true),
                  child: const Icon(Icons.close_rounded))
            ],
          ),
          const SizedBox(height: 8),
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              note ??
                  "We recommend that you answer the questions as you see fit and relax and speak your mind.",
              style: CustomTypography().bodyLarge(),
            ),
          )
        ],
      ),
    );
  }
}
