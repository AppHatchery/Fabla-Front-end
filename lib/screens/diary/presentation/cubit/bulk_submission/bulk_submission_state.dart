part of 'bulk_submission_cubit.dart';

sealed class BulkSubmissionState extends Equatable {
  const BulkSubmissionState();

  @override
  List<Object> get props => [];
}

final class BulkSubmissionInitial extends BulkSubmissionState {}

final class BulkSubmissionInProgress extends BulkSubmissionState {
  final List<DiarySubmission> diaries;
  final int counter;

  const BulkSubmissionInProgress(this.diaries, {this.counter = 0});

  @override
  List<Object> get props => [diaries, counter];
}

final class BulkSubmissionSuccess extends BulkSubmissionState {}

final class BulkSubmissionFailed extends BulkSubmissionState {
  final List<DiarySubmission> diaries;
  final int failedCount;

  const BulkSubmissionFailed(this.diaries, this.failedCount);

  @override
  List<Object> get props => [diaries, failedCount];
}

final class BulkSubmissionError extends BulkSubmissionState {
  final String message;

  const BulkSubmissionError(this.message);

  @override
  List<Object> get props => [message];
}
