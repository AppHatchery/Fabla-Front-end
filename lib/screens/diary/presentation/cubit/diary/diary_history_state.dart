part of 'diary_history_cubit.dart';

sealed class DiaryHistoryState extends Equatable {
  const DiaryHistoryState();

  @override
  List<Object> get props => [];
}

class DiaryHistoryInitial extends DiaryHistoryState {
  const DiaryHistoryInitial();
}

class DiaryHistoryLoading extends DiaryHistoryState {
  const DiaryHistoryLoading();
}

class DiaryHistoryLoaded extends DiaryHistoryState {
  final Map<String, List<DiaryModel>> groupedDiaries;
  final bool hasMore;
  final int currentPage;

  const DiaryHistoryLoaded({
    required this.groupedDiaries,
    required this.hasMore,
    required this.currentPage,
  });

  @override
  List<Object> get props => [groupedDiaries, hasMore, currentPage];
}

class DiaryHistoryLoadingMore extends DiaryHistoryState {
  final Map<String, List<DiaryModel>> currentDiaries;

  const DiaryHistoryLoadingMore(this.currentDiaries);

  @override
  List<Object> get props => [currentDiaries];
}

class DiaryHistoryError extends DiaryHistoryState {
  final String message;
  const DiaryHistoryError(this.message);

  @override
  List<Object> get props => [message];
}