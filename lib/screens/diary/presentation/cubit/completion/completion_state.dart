part of 'completion_cubit.dart';

sealed class CompletionState extends Equatable {
  const CompletionState();

  @override
  List<Object> get props => [];
}

final class CompletionInitial extends CompletionState {
  const CompletionInitial();
}

final class CompletionLoading extends CompletionState {
  const CompletionLoading();
}

final class CompletionLoaded extends CompletionState {
  final DiaryModel diary;
  final List<DiaryModel> diaries;
  final List<StudyModel> studies;
  const CompletionLoaded(
      {required this.diary, required this.diaries, required this.studies});

  @override
  List<Object> get props => [diary, diaries, studies];
}

final class CompletionError extends CompletionState {
  final String message;
  const CompletionError({required this.message});

  @override
  List<Object> get props => [message];
}
