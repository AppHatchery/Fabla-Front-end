import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:flutter/material.dart';

import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_typography.dart';

class TodaysDiaryList extends StatelessWidget {
  final List<Diary> diaries;
  const TodaysDiaryList({super.key, required this.diaries});

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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: diaries.length,
          itemBuilder: (context, index) {
            return DiaryCard(diary: diaries[index]);
          },
        ),
      ],
    );
  }
}
