part of 'summary_cubit.dart';

sealed class SummaryState extends Equatable {
  const SummaryState();

  @override
  List<Object> get props => [];
}

enum AnswerSubmissionStatus { pending, uploading, successful, failed }

final class SummaryInitial extends SummaryState {
  const SummaryInitial();
}

final class SummaryLoading extends SummaryState {
  const SummaryLoading();
}

final class SummaryLoaded extends SummaryState {
  final DiaryModel diary;
  final Map<int, AnswerSubmissionStatus> submissionStatuses;
  const SummaryLoaded(this.diary,
      {this.submissionStatuses = const <int, AnswerSubmissionStatus>{}});

  @override
  List<Object> get props => [diary, submissionStatuses];
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

final class SubmitNoInternet extends SummaryState {
  const SubmitNoInternet();
}
