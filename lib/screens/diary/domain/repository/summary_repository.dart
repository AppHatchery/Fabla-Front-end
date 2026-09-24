import 'dart:async';

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
import 'answer_repository.dart';
import 'diary_repository.dart';

/// Upper bound on a single diary submission, across every network attempt and
/// retry it makes. Past this the UI shows a failure rather than a spinner.
const Duration _submissionDeadline = Duration(minutes: 5);

class SummaryRepository {
  /// Submissions currently uploading, keyed by diary id.
  ///
  /// Static because callers construct `SummaryRepository()` freshly at each
  /// call site, so an instance field would not see an upload started elsewhere.
  static final Map<int, Future<bool>> _inFlight = {};

  /// The collaborators default to real repositories, so the existing
  /// `SummaryRepository()` call sites are unaffected. They are injectable
  /// because each one binds an ObjectBox `Box` as a field initializer, which a
  /// unit test has no store to satisfy.
  SummaryRepository({
    AnswerRepository? answerRepository,
    PromptRepository? promptRepository,
    DiaryRepository? diaryRepository,
    SetupRepository? setupRepository,
  })  : answerRepository = answerRepository ?? AnswerRepository(),
        promptRepository = promptRepository ?? PromptRepository(),
        diaryRepository = diaryRepository ?? DiaryRepository(),
        setupRepository = setupRepository ?? SetupRepository();

  final AnswerRepository answerRepository;
  final PromptRepository promptRepository;
  final DiaryRepository diaryRepository;
  final SetupRepository setupRepository;

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
            newPrompt.responseType == ResponseType.instruction;
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

  /// Submits [diary] and, on success, advances it via
  /// `diaryRepository.updateDiary`.
  ///
  /// Returns:
  /// - `true` — uploaded and recorded, or already recorded by an earlier run.
  /// - `false` — the upload failed; the diary is untouched and still pending.
  /// - `null` — nothing was sent (no connectivity), or the upload is still
  ///   running past [_submissionDeadline] and its outcome is not yet known.
  ///   Callers treat null as "saved locally, try again later" rather than as a
  ///   failure, because the upload may still complete and record itself.
  ///
  Future<bool?> submitDiary(DiaryModel diary) async {
    // Checked before connectivity: if this entry is already on the server,
    // that is true whether or not the phone is online, and reporting "saved,
    // try again later" for it would invite the very re-upload guarded against.
    if (_alreadyRecorded(diary)) {
      dev.log("Entry ${diary.currentEntry} of diary ${diary.id} is already "
          "recorded — skipping re-upload",
          name: "SummaryRepository - submitDiary");
      return true;
    }

    final hasInternet = await checkForInternet();
    if (!hasInternet) return null;

    final participant = setupRepository.getParticipant();
    if (participant == null) {
      // Reported rather than merely returned: no participant means onboarding
      // state is gone, and the participant is now silently unable to submit
      // anything. The `participant!` this replaced threw a TypeError that the
      // catch below turned into a Crashlytics report, so dropping the report
      // with the null check would have made a study-blocking fault invisible.
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

    // One upload per diary at a time. The deadline below bounds how long the
    // UI waits, not how long the upload runs, so a diary can still be in
    // flight when the user tries again — joining that run instead of starting
    // a second one is what keeps a slow submission from being sent twice.
    final pending = _inFlight[diary.id] ??=
        _uploadAndRecord(participant.studyCode, diary)
            .whenComplete(() => _inFlight.remove(diary.id));

    try {
      return await pending.timeout(_submissionDeadline);
    } on TimeoutException catch (e, stackTrace) {
      dev.log("Submission exceeded ${_submissionDeadline.inMinutes}m deadline",
          name: "SummaryRepository - submitDiary");
      CrashlyticsService().recordError(e, stackTrace,
          context: {
            'Diary': diary.name.toString(),
            'DiaryID': diary.id.toString(),
            'CurrentEntry': diary.currentEntry.toString(),
          },
          reason: 'Diary submission exceeded deadline in submitDiary');
      // Null routes to the "saved on your phone, submit when you're back
      // online" state, which is what is actually true: the diary is untouched
      // locally, the upload may still finish and record itself, and the diary
      // stays in the pending backlog either way. Returning false would claim a
      // failure we do not know to have happened.
      return null;
    }
  }

  /// Whether the submission [snapshot] stands for has already been recorded.
  ///
  /// [_inFlight] only dedupes *overlapping* calls and is cleared the moment a
  /// run finishes, so it cannot help once a run has completed. That gap is
  /// ordinary rather than exotic: [_submissionDeadline] is far shorter than the
  /// budget the network layer permits, so the UI routinely gives up, marks the
  /// diary retryable, and lets the upload finish afterwards.
  ///
  /// Neither retry surface re-reads the diary — `retryFailedSubmissions`
  /// carries the `DiaryModel` it was handed through `copyWith`, and
  /// `diarysummary.dart` reuses the model the page was built with. A re-upload
  /// from that stale snapshot would not overwrite anything: the S3 object name
  /// carries a per-run timestamp, so it lands under a new key and writes a
  /// second DynamoDB item set, while locally `currentEntry` is recomputed from
  /// the same stale base and lands on the value it already held. Nothing looks
  /// wrong on the phone; the duplicate exists only on the server.
  ///
  /// [_uploadAndRecord] advances `currentEntry` by exactly one per recorded
  /// submission, so a stored value ahead of the snapshot's means this entry is
  /// already up.
  bool _alreadyRecorded(DiaryModel snapshot) {
    final stored = diaryRepository.getDiaryByID(snapshot.id);
    // No local record to compare against — proceed rather than silently
    // swallow a submission on the strength of a missing row.
    if (stored == null) return false;
    return stored.currentEntry > snapshot.currentEntry;
  }

  /// Uploads [diary] and, on success, records the submission locally.
  ///
  /// Kept separate from [submitDiary] so the recording happens when the upload
  /// actually finishes rather than only while a caller is still waiting — a
  /// submission that outlives [_submissionDeadline] still advances the diary,
  /// so it is not offered for resubmission and cannot be uploaded twice.
  ///
  /// Never throws: the future is left unawaited once the deadline passes, so an
  /// escaping error would surface as an unhandled async exception.
  Future<bool> _uploadAndRecord(String participantID, DiaryModel diary) async {
    try {
      final uploaded = await upload(participantID, diary);

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
        await modifyHomeProgressTracking(studyID: diary.studyID, submissions: 1, activateAnimation: true);
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
