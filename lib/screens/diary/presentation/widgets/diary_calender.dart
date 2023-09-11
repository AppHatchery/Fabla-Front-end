import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../../data/diary.dart';

class DiaryCalender extends StatelessWidget {
  final List<Diary> diaries;
  final ValueChanged<bool> refresh;
  const DiaryCalender(
      {super.key, required this.diaries, required this.refresh});

  @override
  Widget build(BuildContext context) {
    final currentDate = DateTime.now();
    final formattedDate = DateFormat("MMMM d',' y").format(currentDate);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formattedDate,
          style: CustomTypography()
              .titleLarge(color: CustomColors.textNormalContent),
          textAlign: TextAlign.left,
        ),
        const SizedBox(
          height: 6,
        ),
        ListView.builder(
          padding: const EdgeInsets.all(0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: diaries.length,
          itemBuilder: (context, index) {
            final diary = diaries[index];
            return DiaryCard(
              diary: diary,
              refresh: refresh,
            );
          },
        )
      ],
    );
  }
}
