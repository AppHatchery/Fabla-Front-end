import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';

class DiarySubmission {
  final StudyModel study;
  final DiaryModel diary;
  final SubmissionStatus status;

  DiarySubmission(
      {required this.diary,
      required this.study,
      this.status = SubmissionStatus.pending});

  DiarySubmission copyWith({SubmissionStatus? status}) {
    return DiarySubmission(
      diary: diary,
      study: study,
      status: status ?? this.status,
    );
  }
}
