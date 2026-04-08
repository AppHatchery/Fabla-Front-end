import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';

import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Function to calculate earned incentives based on diary submissions and completion rates.
/// This function is triggered after a submission of entries
///
/// Returns a `bool` value after the calculated incentives are submitted to AWS.
Future<bool> calculateEarnedIncentivesForAWS(
    {required String participantID}) async {
  final repository = SetupRepository();
  final experiment = repository.getExperiment();
  final experimentCode = experiment.login;
  final diaryRepository = DiaryRepository();

  // Get the all diaries with multiple entries
  final diaries = diaryRepository.getAllDiariesWithMultipleEntries();

  final studies = diaryRepository.getAllStudies();

  // Make a map of study to diaries
  // where the studyID is equal to the diary's studyID
  final Map<StudyModel, List<DiaryModel>> studyDiariesMap = {};
  for (var study in studies) {
    studyDiariesMap[study] =
        diaries.where((d) => d.studyID == study.studyId).toList();
  }

  double earned = 0;
  String? currency = studies.firstOrNull?.incentive.currency;

  studyDiariesMap.forEach((study, diaries) {
    int completedCount = 0;

    // Check if the diary is submitted
    // and add the incentive amount to the earned amount
    for (var diary in diaries) {
      if (diary.status == DiaryStatus.submitted) {
        earned += study.incentive.amount;
        completedCount++;
      }
    }

    // Check if the completion rate is greater than or equal to the threshold
    // and add the bonus amount to the earned amount
    double completionRate = completedCount / diaries.length;
    if (completionRate * 100 >= study.incentive.threshold) {
      earned += study.incentive.bonus;
    }
  });

  dev.log("Earned: $earned", name: "Incentives - submitDiary");
  final env = kDebugMode ? "dev" : "Prod";
  final entry = PromptEntry(
    participantID: participantID,
    experimentCode: experimentCode,
    questionTitle: "Incentives Earned",
    diaryID: '',
    promptID: '',
    response: formatMoney(earned, currency: currency),
    respondedAt: "",
    questionsType: "Incentives",
    required: true,
    environment: env,
  );

  return await uploadNonAudioData([entry]);
}
