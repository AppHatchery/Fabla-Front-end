import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'completion_state.dart';

class CompletionCubit extends Cubit<CompletionState> {
  final DiaryRepository _diaryRepository = DiaryRepository();

  CompletionCubit() : super(const CompletionInitial());

  void completeDiary(DiaryModel diary) async {
    final today = DateTime.now();
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    try {
      emit(const CompletionLoading());
      final newDiary = _diaryRepository.getDiaryByID(diary.id);

      final diaries = _diaryRepository.getRangeDiaries(
          monday.subtract(const Duration(days: 1)),
          sunday.add(const Duration(days: 1)));

      final ids = diaries.map((e) => e.studyID).toSet().toList();
      final studies = await _diaryRepository.getStudies(ids);

      emit(CompletionLoaded(
          diary: newDiary!, diaries: diaries, studies: studies));
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      CrashlyticsService().recordError(e, stackTrace,
          reason: 'Error in CompletionCubit.completeDiary');
      emit(CompletionError(message: e.toString()));
    }
  }
}
