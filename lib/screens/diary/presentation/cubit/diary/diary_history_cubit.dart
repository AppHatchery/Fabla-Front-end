import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/utils/statuses.dart';
import '../../../../../core/utils/types.dart';
import '../../../data/diary.dart';
import '../../../data/tag.dart';

part 'diary_history_state.dart';

class DiaryHistoryCubit extends Cubit<DiaryHistoryState> {
  DiaryHistoryCubit() : super(const DiaryHistoryInitial());
  DiaryRepository repository = DiaryRepository();

  Future<void> loadPastDiaries() async {
    try {
      emit(const DiaryHistoryLoading());
      //final diary = await repository.getAllDiaries();
      List<DiaryModel> unfilteredDiaries = repository.getAllDiaries();

      final now = DateTime.now();
      final due = now.hour >= 4
          ? DateTime(now.year, now.month, now.day, 4, 0, 0)
              .add(const Duration(days: 1))
          : DateTime(now.year, now.month, now.day, 4, 0, 0);

      final filteredDiaries =
          unfilteredDiaries.where((diary) => diary.due.isBefore(due)).toList();

      filteredDiaries.sort((a, b) => b.due.compareTo(a.due));

      for (var diary in unfilteredDiaries) {
        diary.tags = _getTags(diary);
      }

      emit(DiaryHistoryLoaded(filteredDiaries));
    } catch (e) {
      emit(const DiaryHistoryError("Something went wrong"));
    }
  }

  List<Tag> _getTags(DiaryModel diary) {
    List<Tag> tags = [];

    if (diary.status == DiaryStatus.submitted) {
      tags.add(const Tag(text: "Done", type: TagType.time));
    } else if (diary.status == DiaryStatus.missed) {
      tags.add(const Tag(text: "Missed", type: TagType.time));
    } else if (diary.status == DiaryStatus.complete) {
      tags.add(const Tag(text: "Awaiting Submission", type: TagType.time));
    } else if (diary.status == DiaryStatus.ongoing) {
      tags.add(const Tag(text: "Ongoing", type: TagType.time));
    } else if (diary.status == DiaryStatus.idle) {
      tags.add(const Tag(text: "Ready to Start", type: TagType.time));
    }

    return tags;
  }
}
