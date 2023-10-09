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
      List<Diary> unfilteredDiaries = await repository.getAllDiaries();
      for (var diary in unfilteredDiaries) {
        diary.tags = _getTags(diary);
      }
      List<Diary> unSubmittedDiaries = unfilteredDiaries
          .where((element) => element.status == DiaryStatus.complete)
          .toList();
      List<Diary> diaries = unfilteredDiaries
          .where((element) => element.status != DiaryStatus.complete)
          .toList();
      diaries
          .sort((a, b) => a.status.toString().compareTo(b.status.toString()));
      emit(DiaryHistoryLoaded(diaries, unSubmittedDiaries));
    } catch (e) {
      emit(const DiaryHistoryError("Something went wrong"));
    }
  }

  List<Tag> _getTags(Diary diary) {
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
