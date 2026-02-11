import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/empty_state.dart';
import 'package:flutter/material.dart';

import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_typography.dart';

class TodaysDiaryList extends StatelessWidget {
  final List<DiaryModel> diaries;
  final ValueChanged<bool> refresh;
  final String getPageName;
  const TodaysDiaryList(
      {super.key,
      required this.diaries,
      required this.refresh,
      required this.getPageName});

  @override
  Widget build(BuildContext context) {
    // Filter diaries to exclude submitted and past due entries
    final _diaries = diaries
        .where((diary) =>
            diary.status != DiaryStatus.submitted &&
            diary.due.isAfter(DateTime.now()))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Entries",
          style: CustomTypography().headlineMedium(),
          textAlign: TextAlign.left,
        ),
        const SizedBox(
          height: 24,
        ),
        _diaries.isEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 26.0),
                child: const DayComplete(),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _diaries.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DiaryCard(
                      diary: _diaries[index],
                      refresh: (value) => refresh(value),
                      pageName: getPageName,
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
