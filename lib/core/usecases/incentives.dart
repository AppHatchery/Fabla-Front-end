import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:http/http.dart' as http;

import 'dart:developer' as dev;

/// Function to calculate earned incentives based on diary submissions and completion rates.
/// This function is triggered after a submission of entries
///
/// In addition to the overall "Incentives" total, this submits a "StudyIncentive"
/// entry scoped to [studyID] (the study the just-submitted diary belongs to), and a
/// one-time "BonusEarned" entry the first time that study's completion threshold is met.
///
/// [setupRepository], [diaryRepository], [preferenceService], [secureSave], and [client]
/// can be injected for testing; defaults to real instances otherwise.
///
/// Returns a `bool` value after the calculated incentives are submitted to AWS.
Future<bool> calculateEarnedIncentivesForAWS({
  required String participantID,
  required int studyID,
  SetupRepository? setupRepository,
  DiaryRepository? diaryRepository,
  PreferenceService? preferenceService,
  SecureSave? secureSave,
  http.Client? client,
}) async {
  final repository = setupRepository ?? SetupRepository();
  final experiment = repository.getExperiment();
  final experimentCode = experiment.login;
  final diaryRepo = diaryRepository ?? DiaryRepository();
  final preferences = preferenceService ?? PreferenceService();

  // Get the all diaries with multiple entries
  final diaries = diaryRepo.getAllDiariesWithMultipleEntries();

  final studies = diaryRepo.getAllStudies();

  // Make a map of study to diaries
  // where the studyID is equal to the diary's studyID
  final Map<StudyModel, List<DiaryModel>> studyDiariesMap = {};
  for (var study in studies) {
    studyDiariesMap[study] =
        diaries.where((d) => d.studyID == study.studyId).toList();
  }

  double earned = 0;
  String? currency = studies.firstOrNull?.incentive.currency;

  StudyModel? currentStudy;
  double currentStudyEarned = 0;
  bool bonusJustEarned = false;

  for (final mapEntry in studyDiariesMap.entries) {
    final study = mapEntry.key;
    final studyDiaries = mapEntry.value;
    int completedCount = 0;

    // Check if the diary is submitted
    // and add the incentive amount to the earned amount
    for (var diary in studyDiaries) {
      if (diary.status == DiaryStatus.submitted) {
        earned += study.incentive.amount;
        completedCount++;
      }
    }

    // Check if the completion rate is greater than or equal to the threshold
    // and add the bonus amount to the earned amount
    final double completionRate =
        studyDiaries.isEmpty ? 0.0 : completedCount / studyDiaries.length;
    final bonusAccomplished =
        completionRate * 100 >= study.incentive.threshold;
    if (bonusAccomplished) {
      earned += study.incentive.bonus;
    }

    if (study.studyId == studyID) {
      currentStudy = study;
      currentStudyEarned = completedCount * study.incentive.amount;

      // The bonus is only ever given once per study, so it's only fired
      // the first time the threshold is met for that study.
      final bonusAlreadyGiven = await preferences.getBoolPreference(
              key: 'bonus_given_study_$studyID') ??
          false;
      bonusJustEarned = bonusAccomplished && !bonusAlreadyGiven;
    }
  }

  dev.log("Earned: $earned", name: "Incentives - submitDiary");

  final entries = <PromptEntry>[
    PromptEntry(
      participantID: participantID,
      experimentCode: experimentCode,
      questionTitle: "Incentives Earned",
      diaryID: '',
      promptID: '',
      diaryName: '',
      study: '',
      response: formatMoney(earned, currency: currency),
      respondedAt: DateTime.now().toIso8601String(),
      questionsType: "Incentives",
      required: true,
    ),
  ];

  if (currentStudy != null) {
    final studyCurrency = currentStudy.incentive.currency;

    entries.add(PromptEntry(
      participantID: participantID,
      experimentCode: experimentCode,
      questionTitle: "Study Incentive Earned",
      diaryID: '',
      promptID: '',
      diaryName: '',
      study: currentStudy.name,
      response: formatMoney(currentStudyEarned, currency: studyCurrency),
      respondedAt: DateTime.now().toIso8601String(),
      questionsType: "StudyIncentive",
      required: true,
    ));

    if (bonusJustEarned) {
      entries.add(PromptEntry(
        participantID: participantID,
        experimentCode: experimentCode,
        questionTitle: "Bonus Earned",
        diaryID: '',
        promptID: '',
        diaryName: '',
        study: currentStudy.name,
        response:
            formatMoney(currentStudy.incentive.bonus, currency: studyCurrency),
        respondedAt: DateTime.now().toIso8601String(),
        questionsType: "BonusEarned",
        required: true,
      ));
    }
  }

  final uploaded = await uploadNonAudioData(entries,
      secureSave: secureSave, client: client);

  // Only persist the bonus as given once it has actually been submitted,
  // so a failed upload can still retry on the next diary submission.
  if (uploaded && bonusJustEarned) {
    await preferences.setBoolPreference(
        key: 'bonus_given_study_$studyID', value: true);
  }

  return uploaded;
}
