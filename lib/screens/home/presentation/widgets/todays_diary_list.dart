import 'package:flutter/material.dart';

import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_typography.dart';

class TodaysDiaryList extends StatelessWidget {
  const TodaysDiaryList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Diary",
                style: CustomTypography().headlineMedium(),
                textAlign: TextAlign.left,
              ),
              const SizedBox(
                height: 12,
              ),
              const DiaryCard(),
              const SizedBox(
                height: 12,
              ),
              const DiaryCard()
            ],
          );
  }
}