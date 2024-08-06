import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/utils/statuses.dart';
import '../../../../../core/utils/types.dart';
import '../../../../../services/preference_service.dart';
import '../../../data/diary.dart';
import '../../../data/tag.dart';

part 'diary_state.dart';

class DiaryCubit extends Cubit<DiaryState> {
  DiaryCubit() : super(const DiaryInitial());
  DiaryRepository repository = DiaryRepository();

  Future<void> loadDiaries({DateTime? date}) async {
    final today = date ?? DateTime.now();
    final startDate = DateTime.fromMillisecondsSinceEpoch(
        await PreferenceService().getIntPreference(key: 'startDate') ?? 0);

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
      final diary = repository.getDiary(start, due);
      if (diary != null) {
        final updated =
            diary.copyWith(id: diary.id, studyID: diary.studyID,tags: _getTags(diary));
        emit(DiaryLoaded([updated], startDate));
      } else {
        emit(DiaryLoaded(const [], startDate));
      }
    } catch (e) {
      emit(const DiaryError("Something went wrong"));
    }
  }

  List<Tag> _getTags(DiaryModel diary) {
    final today = DateTime.now();
    List<Tag> tags = [];

    if (diary.status == DiaryStatus.submitted) {
      tags.add(const Tag(text: "Done", type: TagType.time));
    } else if (diary.status == DiaryStatus.missed) {
      tags.add(const Tag(text: "Missed", type: TagType.time));
    } else if (diary.status == DiaryStatus.complete) {
      tags.add(const Tag(text: "Awaiting Submission", type: TagType.time));
    } else if (diary.status == DiaryStatus.ongoing) {
      tags.add(const Tag(text: "Ongoing", type: TagType.time));
    } else if (diary.status == DiaryStatus.idle && diary.start.isAfter(today)) {
      tags.addAll([
        const Tag(text: "13 Questions", type: TagType.questions),
        const Tag(text: "12 Minutes", type: TagType.time)
      ]);
    } else if (diary.status == DiaryStatus.idle) {
      tags.add(const Tag(text: "Ready to Start", type: TagType.time));
    }

    return tags;
  }
}
