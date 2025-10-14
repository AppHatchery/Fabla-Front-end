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
  final TodaysData todaysData;
  final WeeklyData weeklyData;
  final List<StudyModel> allStudies;
  final int weeklyEntries;
  final bool isFinished;
  final Map<StudyModel, DailyGoalData> goalData;

  const HomeLoaded({
    required this.todaysData,
    required this.weeklyData,
    required this.allStudies,
    required this.weeklyEntries,
    required this.isFinished,
    required this.goalData,
  });

  bool get hasAvailableDiaries => todaysData.diaries.isNotEmpty;
  bool get hasGoals => goalData.isNotEmpty;
  bool get shouldShowGoalWidget => hasGoals;
  bool get shouldShowDiaryList => hasAvailableDiaries && !isFinished;
  bool get shouldShowEndState => isFinished;
  bool get shouldShowFreeDay => !hasAvailableDiaries && !isFinished;

  @override
  List<Object> get props => [
        todaysData,
        weeklyData,
        allStudies,
        weeklyEntries,
        isFinished,
        goalData,
      ];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}
