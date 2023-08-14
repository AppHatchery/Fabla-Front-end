import 'package:flutter/material.dart';

import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_typography.dart';

class UnsubmittedDiaryList extends StatelessWidget {
  const UnsubmittedDiaryList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Unsubmitted Diary",
                style: CustomTypography().headlineMedium(),
                textAlign: TextAlign.left,
              ),
              const SizedBox(
                height: 12,
              ),
              const DiaryCard(),

            ],
          );
  }
}