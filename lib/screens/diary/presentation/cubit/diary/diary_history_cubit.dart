import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/diary.dart';

part 'diary_history_state.dart';

class DiaryHistoryCubit extends Cubit<DiaryHistoryState> {
  DiaryHistoryCubit() : super(const DiaryHistoryInitial());
  DiaryRepository repository = DiaryRepository();

  Future<void> loadPastDiaries() async {
    try {
      emit(const DiaryHistoryLoading());

      final history = repository.getAllHistoryDiaries();

      emit(DiaryHistoryLoaded(history));
    } catch (e) {
      emit(const DiaryHistoryError("Something went wrong"));
    }
  }
}
