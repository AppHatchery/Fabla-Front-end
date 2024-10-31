part of 'home_cubit.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final List<DiaryModel> diaries;
  final List<DiaryModel> weeksDiaries;
  final bool available; // any diaries available that day
  final List<StudyModel> studies;
  final int entries;
  const HomeLoaded(this.diaries, this.weeksDiaries, this.available,
      this.studies, this.entries);

  @override
  List<Object> get props =>
      [diaries, weeksDiaries, available, studies, entries];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}
