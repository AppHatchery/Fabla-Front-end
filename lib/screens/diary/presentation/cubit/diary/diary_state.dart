part of 'diary_cubit.dart';

sealed class DiaryState extends Equatable {
  const DiaryState();

  @override
  List<Object> get props => [];
}

class DiaryInitial extends DiaryState {
  const DiaryInitial();
}

class DiaryLoading extends DiaryState {
  const DiaryLoading();
}

class DiaryLoaded extends DiaryState {
  final List<DiaryModel> diaries;
  final DateTime startDate;
  const DiaryLoaded(this.diaries, this.startDate);

  @override
  List<Object> get props => [diaries, startDate];
}

class DiaryError extends DiaryState {
  final String message;
  const DiaryError(this.message);

  @override
  List<Object> get props => [message];
}
