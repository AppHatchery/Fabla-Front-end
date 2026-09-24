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

  /// The submissions as they stood when the exception hit, so the UI shows
  /// what actually succeeded and a retry only re-sends what did not.
  final List<DiarySubmission> diaries;

  /// [diaries] is required rather than defaulting to empty: an emitter that
  /// omitted it would render "0 submissions could not be uploaded" next to an
  /// enabled retry button, and the page would silently drop the record of what
  /// had already succeeded.
  const BulkSubmissionError(this.message, {required this.diaries});

  @override
  List<Object> get props => [message, diaries];
}
