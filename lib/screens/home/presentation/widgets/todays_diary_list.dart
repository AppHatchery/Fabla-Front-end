import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/empty_state.dart';
import 'package:flutter/material.dart';

import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_typography.dart';

class TodaysDiaryList extends StatelessWidget {
  final List<DiaryModel> diaries;
  final ValueChanged<bool> refresh;
  final String Function() getPageName;
  const TodaysDiaryList(
      {super.key,
      required this.diaries,
      required this.refresh,
      required this.getPageName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Entries",
          style: CustomTypography().headlineMedium(),
          textAlign: TextAlign.left,
        ),
        const SizedBox(
          height: 12,
        ),
        diaries.isEmpty
            ? Padding(
              padding: const EdgeInsets.only(top: 26.0),
              child: const DayComplete(),
            )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: diaries.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DiaryCard(
                      diary: diaries[index],
                      refresh: (value) => refresh(value),
                      getPageName: getPageName,
                    ),
                  );
                },
              ),
        const SizedBox(
          height: 12,
        ),
      ],
    );
  }
}
