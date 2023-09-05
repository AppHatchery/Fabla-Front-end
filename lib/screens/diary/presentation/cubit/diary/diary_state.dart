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

class DiaryLoaded extends DiaryState{
  final List<Diary> diaries;
  final List<Diary> unSubmittedDiaries;
  const DiaryLoaded(this.diaries, this.unSubmittedDiaries);


  @override
  List<Object> get props => [diaries];
}

class DiaryError extends DiaryState{
  final String message;
  const DiaryError(this.message);

  @override
  List<Object> get props => [message];
}


