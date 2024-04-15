part of 'summary_cubit.dart';

sealed class SummaryState extends Equatable {
  const SummaryState();

  @override
  List<Object> get props => [];
}

final class SummaryInitial extends SummaryState {
  const SummaryInitial();
}

final class SummaryLoading extends SummaryState {
  const SummaryLoading();
}

final class SummaryLoaded extends SummaryState {
  final DiaryModel diary;
  const SummaryLoaded(this.diary);

  @override
  List<Object> get props => [diary];
}

final class SummaryError extends SummaryState {
  const SummaryError();
}

final class SummarySubmitted extends SummaryState {
  const SummarySubmitted();
}

final class SubmitLoading extends SummaryState {
  const SubmitLoading();
}

final class SubmitError extends SummaryState {
  const SubmitError();
}
