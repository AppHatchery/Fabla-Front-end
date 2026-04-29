import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/core/usecases/connectivity.dart';
import 'package:audio_diaries_flutter/core/usecases/incentives.dart';
import 'package:audio_diaries_flutter/core/usecases/notification_manager.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/prompt_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'dart:developer' as dev;

import '../../../../core/usecases/notifications.dart';
import '../../../../core/utils/statuses.dart';
import '../../data/diary.dart';
import '../../data/prompt.dart';
import 'answer_repository.dart';
import 'diary_repository.dart';

class SummaryRepository {
  final AnswerRepository answerRepository = AnswerRepository();
  final PromptRepository promptRepository = PromptRepository();
  final DiaryRepository diaryRepository = DiaryRepository();
  final SetupRepository setupRepository = SetupRepository();

  /// Asynchronous method to load summary information for a Diary object.
  /// This function iterates through the prompts within the provided Diary instance,
  /// loading summary details for each prompt using the `answerRepository.load(prompt)` method.
  /// The loaded summary details are assigned to corresponding prompts within the Diary.
  ///
  /// Parameters:
  /// - [diary]: The Diary object for which summary information is to be loaded.
  ///
  /// Returns:
  /// A Future containing the updated Diary object with loaded summary details for its prompts.
  ///
  /// Throws:
  /// An exception if an error occurs during the loading process. The caught exception is rethrown after logging an error message.
  ///
  Future<DiaryModel> loadSummary(DiaryModel diary) async {
    try {
      final List<PromptModel> cleanPrompts = [];
      for (final prompt in diary.prompts) {
        final newPrompt = promptRepository.load(diary, prompt.id);
        final isInstruction =
            newPrompt.responseType ==  ResponseType.instruction || newPrompt.responseType == ResponseType.mediaVideo;
        newPrompt.id = prompt.id;
        if (!isInstruction) {
          cleanPrompts.add(newPrompt);
        }
      }
      final newDiary = diary.copyWith(
          id: diary.id,
          studyID: diary.studyID,
          prompts: cleanPrompts,
          activeDays: diary.activeDays,
          submissions: diary.submissions);
      return newDiary;
    } catch (e, stackTrace) {
      dev.log("Error loading summary: $e",
          name: "SummaryRepository - loadSummary");
      CrashlyticsService().recordError(e, stackTrace,
          reason: 'Error loading summary in loadSummary - SummaryRepository');
      rethrow;
    }
  }

  /// Saves a response for a given prompt to a specified path.
  /// This method attempts to save a response associated with the provided prompt to the specified path
  /// using the `answerRepository.saveResponse(prompt, path)` method. Any potential errors during the saving process are caught and logged.
  ///
  /// Parameters:
  /// - [prompt]: The Prompt object for which the response is being saved.
  /// - [path]: The path where the response data is to be saved.
  ///
  /// Note:
  /// Any exceptions that occur during the saving process are caught and logged, allowing the application to handle potential errors gracefully.
  ///
  void saveResponse(PromptModel prompt, String path, String type) {
    try {
      answerRepository.saveResponse(prompt: prompt, response: path, type: type);
    } catch (e) {
      dev.log("Error saving response: $e",
          name: "SummaryRepository - saveResponse");
    }
  }

  /// Removes a response associated with a given prompt from a specified path.
  /// This method attempts to remove the response associated with the provided prompt from the specified path
  /// using the `answerRepository.removeResponse(prompt, path)` method. Any potential errors during the removal process are caught and logged.
  ///
  /// Parameters:
  /// - [prompt]: The Prompt object for which the response is being removed.
  /// - [path]: The path from which the response data is to be removed.
  ///
  /// Note:
  /// Any exceptions that occur during the removal process are caught and logged, allowing the application to handle potential errors gracefully.
  ///
  Future<bool> removeResponse(PromptModel prompt, String? path) async {
    try {
      await answerRepository.removeResponse(prompt, path);
      return true;
    } catch (e) {
      dev.log("Error deleting response: $e",
          name: "SummaryRepository - removeResponse");
      return false;
    }
  }

  /// Asynchronous method to submit a Diary for processing.
  /// This function attempts to submit a provided Diary for processing. It marks the Diary as submitted,
  /// updates its status using `diaryRepository.updateDiary(diary)`, and returns a boolean indicating the submission result.
  ///
  /// Parameters:
  /// - [diary]: The Diary object to be submitted.
  ///
  /// Returns:
  /// A Future<bool> indicating the success or failure of the submission process.
  /// The boolean value indicates whether the submission was successful (true) or encountered an error (false).
  ///
  Future<bool?> submitDiary(DiaryModel diary) async {
    try {
      final hasInternet = await checkForInternet();
      if (!hasInternet) return null;

      final participant = setupRepository.getParticipant();
      final uploaded = await upload(participant!.studyCode, diary);
      final study = await diaryRepository.getStudy(diary.studyID);
      // final entry = diary.status == DiaryStatus.submitted
      //     ? diary.entries
      //     : diary.currentEntry;

      if (uploaded) {
        late DiaryModel newDiary;

        dev.log("Current entry: ${diary.currentEntry}",
            name: "SummaryRepository - submitDiary");

        final List<DateTime> submissions = diary.submissions ?? [];
        submissions.add(DateTime.now());
        if (diary.currentEntry + 1 == diary.entries) {
          newDiary = diary.copyWith(
              id: diary.id,
              studyID: diary.studyID,
              status: DiaryStatus.submitted,
              activeDays: diary.activeDays,
              currentEntry: diary.currentEntry + 1,
              submissions: submissions);
        } else {
          newDiary = diary.copyWith(
              id: diary.id,
              studyID: diary.studyID,
              status: DiaryStatus.idle,
              activeDays: diary.activeDays,
              currentEntry: diary.currentEntry + 1,
              submissions: submissions);
        }

        diaryRepository.updateDiary(newDiary);

        // Cancel notifications if diary is complete
        // Schedule daily goal notifications if diary is not complete
        if (diary.currentEntry + 1 >= diary.entries) {
          NotificationManager().cancelDiaryNotifications(diary.id);
        } else if (diary.currentEntry + 1 < study!.goals.daily) {
          dailyGoalNotification(diary.id);
        }
        cancelContinueNotifications(diary.id);
        calculateEarnedIncentivesForAWS(participantID: participant.studyCode);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      dev.log("Error submitting diary: $e",
          name: "SummaryRepository - submitDiary");
      return false;
    }
  }

  /// Asynchronous method to calculate earned incentives for a specific study per submission.
  /// This function calculates the total amount earned based on the completion status of all diaries
  /// within the same study as the provided diary. It determines if the user has achieved the bonus
  /// incentive by checking if the completion rate exceeds the study's bonus threshold percentage.
  ///
  /// Parameters:
  /// - [diary]: The DiaryModel instance used to identify the study and related diaries.
  ///
  Future<void> calculateEarnedIncentives(DiaryModel diary) async {
    final studyDiaries = diaryRepository
        .getAllDiariesWithMultipleEntries()
        .where((d) => d.studyID == diary.studyID)
        .toList();

    final study = diaryRepository
        .getAllStudies()
        .firstWhere((study) => study.studyId == diary.studyID);

    double earned = 0;
    bool bonusAchieved = false;

    // Count completed diaries
    int completedCount = 0;
    for (var d in studyDiaries) {
      if (d.status == DiaryStatus.submitted) {
        completedCount++;
        earned += study.incentive.amount;
      }
    }

    // Check if bonus threshold is met
    double completionRate = completedCount / studyDiaries.length;
    if (completionRate * 100 >= study.incentive.threshold) {
      earned += study.incentive.bonus;
      bonusAchieved = true;
    }

    return await PendoService.track('Incentives', {
      'Earned': formatMoney(earned, currency: study.incentive.currency),
      'BonusAchieve': bonusAchieved,
      'Study': study.name
    });
  }
}
