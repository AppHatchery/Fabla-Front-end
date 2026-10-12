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
  /// What happened during the failed submission, for the developer mode debug
  /// panel. Left out of [props]: two failures are the same state to the UI.
  final DebugTrace? trace;
  const SubmitError({this.trace});
}

final class SubmitNoInternet extends SummaryState {
  /// The trace of the submission that found no connection, for the developer
  /// mode debug panel. Left out of [props], like [SubmitError.trace].
  final DebugTrace? trace;
  const SubmitNoInternet({this.trace});
}
