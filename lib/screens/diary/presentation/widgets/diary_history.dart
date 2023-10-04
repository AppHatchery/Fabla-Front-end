import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/custom_colors.dart';
import '../../data/diary.dart';

class DiaryHistory extends StatelessWidget {
  final List<Diary> diaries;
  final ValueChanged<bool> refresh;

  const DiaryHistory({super.key, required this.diaries, required this.refresh});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final due = now.hour >= 4
        ? DateTime(now.year, now.month, now.day, 4, 0, 0)
            .add(const Duration(days: 1))
        : DateTime(now.year, now.month, now.day, 4, 0, 0);
    final filteredDiaries =
        diaries.where((diary) => diary.due.isBefore(due)).toList();

    filteredDiaries.sort((a, b) => b.due.compareTo(a.due));

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var diary in filteredDiaries)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(diary.start),
                style: CustomTypography()
                    .titleLarge(color: CustomColors.textNormalContent),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 6),
              DiaryCard(
                diary: diary,
                refresh: (value) => refresh(value),
              ),
              const SizedBox(height: 12),
            ],
          ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  final DateFormat formatter = DateFormat("MMMM d',' y");
  return formatter.format(date);
}


/* final currentDate = DateTime.now();
    final formattedDate = DateFormat("MMMM d y").format(currentDate);*/
  /*@override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today, June 6",
          style: CustomTypography()
              .titleLarge(color: CustomColors.textNormalContent),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 6,),
        ListView.builder(
          itemCount: diaries.length,
          itemBuilder: (context, index){
            return DiaryCard(
              diary: diaries[index],
              refresh: (value) => refresh(value)
            );
          },
        )
        //const DiaryCard()
      ],
    );
  }
}*/
