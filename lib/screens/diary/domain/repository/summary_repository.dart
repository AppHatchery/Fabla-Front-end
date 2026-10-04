import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/core/usecases/connectivity.dart';
import 'package:audio_diaries_flutter/core/usecases/home_progress_tracking.dart';
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
import '../entities/answer.dart';
import 'answer_repository.dart';
import 'diary_repository.dart';

class SummaryRepository {
  /// Submissions currently uploading, keyed by diary id. Static because each
  /// call site constructs its own `SummaryRepository()`.
  static final Map<int, Future<bool>> _inFlight = {};

  SummaryRepository({
    AnswerRepository? answerRepository,
    PromptRepository? promptRepository,
    DiaryRepository? diaryRepository,
    SetupRepository? setupRepository,
    Future<bool> Function(String participantID, DiaryModel diary)? uploader,
  })  : answerRepository = answerRepository ?? AnswerRepository(),
        promptRepository = promptRepository ?? PromptRepository(),
        diaryRepository = diaryRepository ?? DiaryRepository(),
        setupRepository = setupRepository ?? SetupRepository(),
        _upload = uploader ?? upload;

  final AnswerRepository answerRepository;
  final PromptRepository promptRepository;
  final DiaryRepository diaryRepository;
  final SetupRepository setupRepository;
  final Future<bool> Function(String participantID, DiaryModel diary) _upload;

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
      // Load ALL prompts with their current-entry answers, sorted by question_number.
      final allPrompts = promptRepository.loadAllWithAnswers(diary);

      // Walk prompts in order so that earlier answers inform later conditions
      // (mirrors the question-flow evaluation order).
      final Map<int, Answer> answersMap = {};
      final List<PromptModel> visiblePrompts = [];

      for (final prompt in allPrompts) {
        if (prompt.responseType == ResponseType.instruction) continue;

        final shouldShow = prompt.shouldShow(answersMap);

        if (shouldShow) {
          visiblePrompts.add(prompt);
          if (prompt.answer != null) {
            answersMap[prompt.questionNumber] = prompt.answer!;
          }
        } else if (prompt.answer != null) {
          // Prompt is on a stale branch — clear its answer so it is not
          // submitted and does not pollute future condition checks.
          await promptRepository.clearAnswer(diary, prompt);
        }
      }

      return diary.copyWith(
          id: diary.id,
          studyID: diary.studyID,
          prompts: visiblePrompts,
          activeDays: diary.activeDays,
          submissions: diary.submissions);
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

  /// Submits [diary] and, on success, advances it via
  /// `diaryRepository.updateDiary`.
  ///
  /// Returns:
  /// - `true` — uploaded and recorded, or already recorded by an earlier run.
  /// - `false` — the upload failed; the diary is untouched and still pending.
  /// - `null` — nothing was sent (no connectivity).
  ///
  Future<bool?> submitDiary(DiaryModel diary) async {
    // Before the connectivity check: an already-recorded entry is done even
    // offline.
    if (_alreadyRecorded(diary)) {
      dev.log(
          "Entry ${diary.currentEntry} of diary ${diary.id} is already "
          "recorded — skipping re-upload",
          name: "SummaryRepository - submitDiary");
      return true;
    }

    final hasInternet = await checkForInternet();
    if (!hasInternet) return null;

    final participant = setupRepository.getParticipant();
    if (participant == null) {
      // Reported: without a participant no diary can be submitted.
      dev.log("No participant on record — cannot submit diary ${diary.id}",
          name: "SummaryRepository - submitDiary");
      CrashlyticsService().recordError(
          StateError('getParticipant() returned null'), StackTrace.current,
          context: {
            'Diary': diary.name.toString(),
            'DiaryID': diary.id.toString(),
            'CurrentEntry': diary.currentEntry.toString(),
          },
          reason: 'Missing participant in submitDiary - SummaryRepository');
      return false;
    }

    // Join an upload already running for this diary. No deadline: iOS
    // suspension would fire it for a diary that then records. The block body
    // matters: `remove` returns this future, and whenComplete would await it.
    return _inFlight[diary.id] ??=
        _uploadAndRecord(participant.studyCode, diary).whenComplete(() {
      _inFlight.remove(diary.id);
    });
  }

  /// Whether an earlier run already recorded the entry [snapshot] stands for.
  ///
  /// Retry paths resubmit the model they were handed rather than re-reading
  /// it, so without this an entry already on the server would be uploaded
  /// again. [_uploadAndRecord] advances `currentEntry` by one per entry.
  bool _alreadyRecorded(DiaryModel snapshot) {
    final stored = diaryRepository.getDiaryByID(snapshot.id);
    // No stored row: upload rather than drop it.
    if (stored == null) return false;
    return stored.currentEntry > snapshot.currentEntry;
  }

  /// Uploads [diary] and, on success, records the submission locally.
  Future<bool> _uploadAndRecord(String participantID, DiaryModel diary) async {
    try {
      final uploaded = await _upload(participantID, diary);

      if (uploaded) {
        final study = await diaryRepository.getStudy(diary.studyID);
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
              submissions: submissions,
              completions: diary.completions);
        } else {
          newDiary = diary.copyWith(
              id: diary.id,
              studyID: diary.studyID,
              status: DiaryStatus.idle,
              activeDays: diary.activeDays,
              currentEntry: diary.currentEntry + 1,
              submissions: submissions,
              completions: diary.completions);
        }

        await diaryRepository.updateDiary(newDiary);

        // Cancel notifications if diary is complete
        // Schedule daily goal notifications if diary is not complete
        if (diary.currentEntry + 1 >= diary.entries) {
          NotificationManager().cancelDiaryNotifications(diary.id);
        } else if (diary.currentEntry + 1 < study!.goals.daily) {
          dailyGoalNotification(diary.id);
        }
        cancelContinueNotifications(diary.id);
        calculateEarnedIncentivesForAWS(
            participantID: participantID, studyID: diary.studyID);
        await modifyHomeProgressTracking(
            studyID: diary.studyID, submissions: 1, activateAnimation: true);
        return true;
      } else {
        return false;
      }
    } catch (e, stackTrace) {
      dev.log("Error submitting diary: $e",
          name: "SummaryRepository - submitDiary");
      CrashlyticsService().recordError(e, stackTrace,
          context: {
            'Diary': diary.name.toString(),
            'DiaryID': diary.id.toString(),
            'CurrentEntry': diary.currentEntry.toString(),
          },
          reason: 'Unhandled exception in submitDiary - SummaryRepository');
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
        .where((study) => study.studyId == diary.studyID)
        .firstOrNull;
    if (study == null) return;

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
