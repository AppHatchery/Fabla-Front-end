import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'completion_state.dart';

class CompletionCubit extends Cubit<CompletionState> {
  final DiaryRepository _diaryRepository = DiaryRepository();

  CompletionCubit() : super(const CompletionInitial());

  void completeDiary(DiaryModel diary) {
    final today = DateTime.now();
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    try {
      emit(const CompletionLoading());
      final study = _diaryRepository.getStudy(diary.studyID);
      final newDiary = _diaryRepository.getDiaryByID(diary.id);
      final diaries = _diaryRepository.getRangeDiaries(
          monday.subtract(const Duration(days: 1)),
          sunday.add(const Duration(days: 1)));
      emit(CompletionLoaded(
          diary: newDiary!, diaries: diaries, study: study!));
    } catch (e) {
      debugPrint(e.toString());
      emit(CompletionError(message: e.toString()));
    }
  }
}
