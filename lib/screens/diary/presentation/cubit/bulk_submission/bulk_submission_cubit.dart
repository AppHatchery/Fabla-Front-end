import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/bulk_submission.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/summary_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'bulk_submission_state.dart';

class BulkSubmissionCubit extends Cubit<BulkSubmissionState> {
  BulkSubmissionCubit() : super(BulkSubmissionInitial());
  final SummaryRepository _summaryRepository = SummaryRepository();
  void startBulkSubmission(List<DiarySubmission> submissions) async {
    final _submissions = List<DiarySubmission>.from(submissions);
    emit(BulkSubmissionInProgress(_submissions));

    try {
      int counter = 0;
      for (final submission in _submissions) {
        final result = await _summaryRepository.submitDiary(submission.diary);
        if (result == null) continue;

        final updatedSubmission = submission.copyWith(
            status:
                result ? SubmissionStatus.successful : SubmissionStatus.failed);

        final index = _submissions
            .indexWhere((element) => element.diary.id == submission.diary.id);
        if (index != -1) {
          _submissions[index] = updatedSubmission;
          counter++;

          emit(BulkSubmissionInProgress(_submissions, counter: counter));
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      if (_submissions
          .any((element) => element.status == SubmissionStatus.failed)) {
        final failedCount = _submissions
            .where((element) => element.status == SubmissionStatus.failed)
            .length;
        emit(BulkSubmissionFailed(_submissions, failedCount));
      } else {
        emit(BulkSubmissionSuccess());
      }
    } catch (e) {
      print("Error during bulk submission: $e");
    }
  }
}
