import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/utils/statuses.dart';
import '../../../../../core/utils/types.dart';
import '../../../data/diary.dart';
import '../../../data/tag.dart';

part 'diary_state.dart';

class DiaryCubit extends Cubit<DiaryState> {
  DiaryCubit() : super(const DiaryInitial());
  DiaryRepository repository = DiaryRepository();

  Future<void> loadDiaries() async {
    final today = DateTime.now();
    final start = today.hour >= 4
        ? DateTime(today.year, today.month, today.day, 4, 0, 0)
        : DateTime(today.year, today.month, today.day, 4, 0, 0)
            .subtract(const Duration(days: 1));
    final due = today.hour >= 4
        ? DateTime(today.year, today.month, today.day, 3, 59, 59)
            .add(const Duration(days: 1))
        : DateTime(today.year, today.month, today.day, 3, 59, 59);
    try {
      emit(const DiaryLoading());
      final diary = await repository.getDiary(start, due);
      if (diary != null) {
        final updated = Diary.copyWith(diary: diary, tags: _getTags(diary));
        List<Diary> unfilterDiaries = [updated];
        List<Diary> unSubmittedDiaries = unfilterDiaries
            .where((element) => element.status == DiaryStatus.complete)
            .toList();
        List<Diary> diaries = unfilterDiaries
            .where((element) => element.status != DiaryStatus.complete)
            .toList();
        diaries
            .sort((a, b) => a.status.toString().compareTo(b.status.toString()));
        emit(DiaryLoaded(diaries, unSubmittedDiaries));
      } else {
        emit(const DiaryLoaded([], []));
      }
    } catch (e) {
      emit(const DiaryError("Something went wrong"));
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
