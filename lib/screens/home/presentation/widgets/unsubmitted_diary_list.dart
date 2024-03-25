import 'package:flutter/material.dart';

import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_typography.dart';
import '../../../diary/data/diary.dart';

class UnsubmittedDiaryList extends StatelessWidget {
  final List<DiaryModel> diaries;
  final ValueChanged<bool> refresh;
  const UnsubmittedDiaryList(
      {super.key, required this.diaries, required this.refresh});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: diaries.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DiaryCard(
                  diary: diaries[index],
                  refresh: (value) => refresh(value),
                  getPageName: () => "",
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
