import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/prompt_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';

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
      for (var i = 0; i < diary.prompts.length; i++) {
        final newPrompt = await promptRepository.load(diary,diary.prompts[i].id);
        newPrompt.id = diary.prompts[i].id;
        diary.prompts[i] = newPrompt;
      }
      return diary;
    } catch (e) {
      print("Error loading summary: $e");
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
  void saveResponse(PromptModel prompt, String path) {
    try {
      answerRepository.saveResponse(prompt: prompt, response: path);
    } catch (e) {
      print("Error saving response: $e");
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
  void removeResponse(PromptModel prompt, String path) {
    try {
      answerRepository.removeResponse(prompt, path);
    } catch (e) {
      print("Error deleting response: $e");
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
  Future<bool> submitDiary(DiaryModel diary) async {
    try {
      final participant = setupRepository.getParticipant();
      final uploaded = await upload(participant!.studyCode, diary);

      if (uploaded) {

      late DiaryModel newDiary;

      if (diary.currentEntry + 1 == diary.entries) {
        newDiary = diary.copyWith(
          id: diary.id,
          status: DiaryStatus.submitted,
        );
      } else {
        newDiary = diary.copyWith(
            id: diary.id,
            status: DiaryStatus.idle,
            currentEntry: diary.currentEntry + 1);
      }

      diaryRepository.updateDiary(newDiary);

      cancelAllDiaryNotifications(diary.id);
      return true;
      }else{
      // //Update the nextStudy date- TBD with provision of study_start_date
      // DateTime now = DateTime.now();
      // var nextStudyDate = DateTime(now.year, now.month, now.day, 4, 0, 0)
      //     .add(const Duration(days: 1));


      //TODO: TO BE REMOVED
      //setupRepository.updateMetaDataFile(nextStudyDate);

      return false;
      
      }
      // } else {
      //   return false;
      // }
    } catch (e) {
      print("Error submitting diary: $e");
      return false;
    }
  }
}
