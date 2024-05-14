import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/protocol.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'completion_state.dart';

class CompletionCubit extends Cubit<CompletionState> {
  final SetupRepository _repository = SetupRepository();
  final DiaryRepository _diaryRepository = DiaryRepository();

  CompletionCubit() : super(const CompletionInitial());

  void completeDiary(DiaryModel diary) {
    final today = DateTime.now();
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    try {
      emit(const CompletionLoading());
      final protocol = _repository.getProtocol();
      final newDiary = _diaryRepository.getDiaryByID(diary.id);
      final diaries = _diaryRepository.getRangeDiaries(
          monday.subtract(const Duration(days: 1)),
          sunday.add(const Duration(days: 1)));
      emit(CompletionLoaded(
          diary: newDiary!, diaries: diaries, protocol: protocol!));
    } catch (e) {
      safePrint(e.toString());
      emit(CompletionError(message: e.toString()));
    }
  }
}
