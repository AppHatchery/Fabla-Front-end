import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/bulk_submission.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/summary_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'bulk_submission_state.dart';

class BulkSubmissionCubit extends Cubit<BulkSubmissionState> {
  final SummaryRepository _summaryRepository;

// to improve testability, we can pass the summary repository as a parameter
  BulkSubmissionCubit({SummaryRepository? summaryRepository})
      : _summaryRepository = summaryRepository ?? SummaryRepository(),
        super(BulkSubmissionInitial());

  void startBulkSubmission(List<DiarySubmission> submissions) async {
    final _submissions = List<DiarySubmission>.from(submissions);
    emit(BulkSubmissionInProgress(_submissions));

    await _processBulkSubmission(_submissions);
  }

  void retryFailedSubmissions(List<DiarySubmission> currentSubmissions) async {
    final _submissions = List<DiarySubmission>.from(currentSubmissions);

    // Reset failed submissions to pending before retrying
    for (int i = 0; i < _submissions.length; i++) {
      if (_submissions[i].status == SubmissionStatus.failed) {
        _submissions[i] =
            _submissions[i].copyWith(status: SubmissionStatus.pending);
      }
    }

    emit(BulkSubmissionInProgress(_submissions));

    await _processBulkSubmission(_submissions);
  }

  Future<void> _processBulkSubmission(
      List<DiarySubmission> _submissions) async {
    try {
      int counter = _submissions
          .where((element) => element.status == SubmissionStatus.successful)
          .length;

      final pendingSubmissions = _submissions
          .where((element) => element.status == SubmissionStatus.pending)
          .toList();

      for (final submission in pendingSubmissions) {
        final result = await _summaryRepository.submitDiary(submission.diary);

        final updatedSubmission = submission.copyWith(
            status: result == true
                ? SubmissionStatus.successful
                : SubmissionStatus.failed);

        final index = _submissions
            .indexWhere((element) => element.diary.id == submission.diary.id);

        if (index != -1) {
          _submissions[index] = updatedSubmission;

          if (result == true) {
            counter++;
          }

          emit(BulkSubmissionInProgress(_submissions, counter: counter));
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      // Check final results
      final failedSubmissions = _submissions
          .where((element) => element.status == SubmissionStatus.failed)
          .toList();

      if (failedSubmissions.isNotEmpty) {
        emit(BulkSubmissionFailed(_submissions, failedSubmissions.length));
      } else {
        emit(BulkSubmissionSuccess());
      }
    } catch (e) {
      print("Error during bulk submission: $e");
      emit(BulkSubmissionError(e.toString()));
    }
  }
}
