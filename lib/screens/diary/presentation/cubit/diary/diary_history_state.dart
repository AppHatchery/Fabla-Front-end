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
  final List<DiaryModel> diaries;
  const DiaryHistoryLoaded(this.diaries);

  @override
  List<Object> get props => [diaries];
}

class DiaryHistoryError extends DiaryHistoryState {
  final String message;
  const DiaryHistoryError(this.message);

  @override
  List<Object> get props => [message];
}
