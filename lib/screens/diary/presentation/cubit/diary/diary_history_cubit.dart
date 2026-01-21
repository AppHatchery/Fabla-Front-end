import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart'
    show CrashlyticsService;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/diary.dart';

part 'diary_history_state.dart';

class DiaryHistoryCubit extends Cubit<DiaryHistoryState> {
  DiaryHistoryCubit() : super(const DiaryHistoryInitial());

  DiaryRepository repository = DiaryRepository();
  static const int pageSize = 10;

  Future<void> loadPastDiaries() async {
    try {
      emit(const DiaryHistoryLoading());

      final result = repository.getPaginatedHistoryDiaries(
        page: 0,
        limit: pageSize,
      );

      emit(DiaryHistoryLoaded(
        groupedDiaries: result.diaries,
        hasMore: result.hasMore,
        currentPage: 0,
      ));
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          reason:
              'Error loading past diaries in loadPastDiaries - DiaryHistoryCubit');
      emit(const DiaryHistoryError("Something went wrong"));
    }
  }

  Future<void> loadMoreDiaries() async {
    final currentState = state;
    if (currentState is! DiaryHistoryLoaded || !currentState.hasMore) return;

    try {
      emit(DiaryHistoryLoadingMore(currentState.groupedDiaries));

      final nextPage = currentState.currentPage + 1;
      final result = repository.getPaginatedHistoryDiaries(
        page: nextPage,
        limit: pageSize,
      );

      final mergedDiaries = Map<String, List<DiaryModel>>.from(
        currentState.groupedDiaries,
      );

      result.diaries.forEach((dateKey, diaries) {
        if (mergedDiaries.containsKey(dateKey)) {
          mergedDiaries[dateKey]!.addAll(diaries);
        } else {
          mergedDiaries[dateKey] = diaries;
        }
      });

      emit(DiaryHistoryLoaded(
        groupedDiaries: mergedDiaries,
        hasMore: result.hasMore,
        currentPage: nextPage,
      ));
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(
        e,
        stackTrace,
        reason: 'Error loading more diaries - DiaryHistoryCubit',
      );
      emit(currentState);
    }
  }
}