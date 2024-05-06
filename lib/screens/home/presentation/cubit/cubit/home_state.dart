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
  final DateTime startDate;
  final Protocol? protocol;
  const HomeLoaded(this.diaries, this.startDate, this.protocol);

  @override
  List<Object> get props => [diaries, startDate];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}
