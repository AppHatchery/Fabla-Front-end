import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/recording.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';

import 'dart:io';
import 'dart:developer' as dev;
import '../../../../core/database/dao/prompt_dao.dart';
import '../../../../main.dart';
import '../../../../objectbox.g.dart';
import '../../data/diary.dart';
import '../entities/answer.dart';
import '../entities/prompt_entity.dart';

class PromptRepository {
  final PromptDAO _promptDAO = PromptDAO(box: Box<Prompt>(objectbox.store));

  /// Loads a prompt from the diary with the specified ID.
  ///
  /// This function retrieves a prompt from the data access object (DAO) based on the provided ID,
  /// transforms the retrieved entity into a model object, and returns the prompt model.
  /// Additionally, it associates the prompt with the answer at the current entry of the diary.
  ///
  /// Parameters:
  /// - [diary]: The diary model from which the prompt is being loaded.
  /// - [id]: The ID of the prompt to load.
  ///
  /// Returns:
  /// A PromptModel object representing the loaded prompt, associated with the current entry's answer.
  PromptModel load(DiaryModel diary, int id) {
    // Retrieve the prompt entity from the DAO
    final prompt = _promptDAO.getPrompt(id);

    // Transform the entity to a model
    final model = PromptModel.fromEntity(prompt);

    // Retrieve the answer associated with the current entry in the diary
    // and associate it with the loaded prompt model
    final modelWithAnswer = model.copyWith(
        answer: prompt.answers.elementAtOrNull(diary.currentEntry));

    // Check conditions to determine if the prompt should be shown
    if (modelWithAnswer.conditions != null &&
        modelWithAnswer.conditions!.isNotEmpty) {
      dev.log("Prompt No: ${modelWithAnswer.questionNumber} has conditions:",
          name: "Prompt Repository - Load Prompt");

      final answers =
          _previousDiaryAnswers(diary, modelWithAnswer.questionNumber);

      if (!modelWithAnswer.shouldShow(answers)) {
        dev.log(
            "Prompt : ${modelWithAnswer.question} will be hidden based on conditions.",
            name: "Prompt Repository - Load Prompt");

        // condition not met, go to next prompt
        // ! check if there is a next prompt before calling load again
        // ! to avoid infinite recursion
        // TODO: Think of ways to optimize this recursive call

        return load(diary, id + 1);
      }
    }

    return modelWithAnswer;
  }

  /// Retrieves previous answers from the diary up to the current prompt.
  /// This function collects answers from prompts that precede the current prompt
  /// in the diary and returns them as a map.
  ///
  /// Parameters:
  /// - [diary]: The diary model from which previous answers are to be retrieved.
  /// - [currentPrompt]: The question number of the current prompt.
  ///
  /// Returns:
  /// A map where the key is the question number and the value is the corresponding Answer object
  Map<int, Answer> _previousDiaryAnswers(DiaryModel diary, int currentPrompt) {
    final Map<int, Answer> answersMap = {};
    final prompts = _promptDAO.getPrompts(id: diary.id);

    for (var prompt in prompts) {
      if (prompt.questionNumber < currentPrompt) {
        final answer = prompt.answers.elementAtOrNull(diary.currentEntry);

        if (answer != null) {
          answersMap[prompt.questionNumber] = answer;
        }
      }
    }

    return answersMap;
  }

  /// Loads all prompts for a diary in one pass, returning models and an answers
  /// map keyed by question number for the current entry. Used by DiarySessionCubit
  /// to build the in-memory session cache.
  ({List<PromptModel> prompts, Map<int, Answer> answers}) loadSession(
      DiaryModel diary) {
    final entities = _promptDAO.getPrompts(id: diary.id);
    final Map<int, Answer> answers = {};
    final List<PromptModel> models = [];

    for (var entity in entities) {
      final answer = entity.answers.elementAtOrNull(diary.currentEntry);
      final model = PromptModel.fromEntity(entity).copyWith(answer: answer);
      models.add(model);
      if (answer != null) {
        answers[entity.questionNumber] = answer;
      }
    }

    return (prompts: models, answers: answers);
  }

  /// Fetches a single prompt by its ObjectBox ID and attaches the current
  /// entry's answer. Used to refresh the cache after a save or remove.
  PromptModel loadPromptWithAnswer(DiaryModel diary, int promptId) {
    final entity = _promptDAO.getPrompt(promptId);
    final answer = entity.answers.elementAtOrNull(diary.currentEntry);
    return PromptModel.fromEntity(entity).copyWith(answer: answer);
  }

  Future<List<PromptModel>> loadAll(DiaryModel diary) async {
    final prompts = _promptDAO.getPrompts(id: diary.id);
    final models =
        prompts.map((prompt) => PromptModel.fromEntity(prompt)).toList();

    final answered = models.map((prompt) {
      return load(diary, prompt.id);
    }).toList();

    return answered;
  }

  /// Saves a response to a prompt in the diary.
  ///
  /// This function saves a response to a prompt within a diary. It determines the type of response (text or audio),
  /// creates a new answer accordingly, associates it with the prompt, and updates the diary's prompt.
  ///
  /// Parameters:
  /// - [diary]: The diary to which the response belongs.
  /// - [prompt]: The prompt for which the response is being saved.
  /// - [response]: The response to be saved.
  /// - [type]: The type of the response, e.g., "audio". Defaults to null.
  ///
  /// Returns:
  /// true if the response is successfully saved, false otherwise.
  bool saveResponse(
      {required Diary diary,
      required PromptModel prompt,
      required dynamic response,
      required String type,
      int? index}) {
    // Determine if the response is for media (audio, image, video)
    final isMediaResponse = ['audio', 'image', 'video'].contains(type);
    // Retrieve the current answer
    final answer = prompt.answer;

    // Allowing multiple responses for text questions
    // If the index is provided, update the response at the specified index
    //! Slider | Multiple | Radio | Timer | Webview : Their index is always 0 because they can only have one response
    //! Audio | Image | Video : Their index is always null because they are being saved as a recording
    dynamic responses = answer?.response ?? [];
    if (index != null && index >= 0 && index < responses.length) {
      if (response != null) {
        responses[index] = response;
      } else {
        responses = null;
      }
    } else if (!isMediaResponse) {
      responses.add(response);
    }

    // Create a new answer based on response type
    final newAnswer = isMediaResponse
        ? Answer(id: 0, date: DateTime.now())
        : Answer(id: 0, date: DateTime.now(), response: responses);

    // Create a recording for media responses
    Recording? createRecording() {
      return isMediaResponse
          ? Recording(prompt.question, response, type, null, DateTime.now())
          : null;
    }

    // Determine how to update the prompt based on existing answer and response type
    Prompt updatedPrompt = _determinePromptUpdate(
      prompt,
      answer,
      newAnswer,
      createRecording(),
    );

    // Associate the updated prompt with the diary
    updatedPrompt.diary.target = diary;

    // Update the prompt in the data access object
    _promptDAO.updatePrompt(updatedPrompt);

    return true;
  }

  /// Separate function to determine if the Prompt is updating or adding a new response
  Prompt _determinePromptUpdate(
    PromptModel prompt,
    Answer? existingAnswer,
    Answer newAnswer,
    Recording? recording,
  ) {
    // No existing answer - use the new answer
    if (existingAnswer == null) {
      if (recording != null) {
        recording.answer.target = newAnswer;
        newAnswer.recordings.add(recording);
      }
      return Prompt.fromModel(prompt.copyWith(answer: newAnswer));
    }

    // Media response with existing answer - add recording to existing answer
    if (recording != null) {
      recording.answer.target = existingAnswer;
      existingAnswer.recordings.add(recording);
      return Prompt.fromModel(prompt.copyWith(answer: existingAnswer));
    }

    // Text response - update existing answer's response
    return Prompt.fromModel(prompt.copyWith(
        answer: existingAnswer.copyWith(response: newAnswer.response)));
  }

  /// Loads all prompts for a diary with their current entry's answers attached.
  /// Sorted by question_number (guaranteed by DAO query order).
  List<PromptModel> loadAllWithAnswers(DiaryModel diary) {
    final entities = _promptDAO.getPrompts(id: diary.id);
    return entities.map((entity) {
      final answer = entity.answers.elementAtOrNull(diary.currentEntry);
      return PromptModel.fromEntity(entity).copyWith(answer: answer);
    }).toList();
  }

  /// Clears all responses and recordings for a prompt at the current diary entry.
  Future<void> clearAnswer(DiaryModel diary, PromptModel prompt) async {
    final answer = prompt.answer;
    if (answer == null) return;

    final recordingBox = Box<Recording>(objectbox.store);
    for (final recording in answer.recordings.toList()) {
      _deleteFile(recording.path);
      if (recording.id != 0) recordingBox.remove(recording.id);
    }

    answer.response = null;
    Box<Answer>(objectbox.store).put(answer);
  }

  Future<bool> removeResponse(Diary diary, PromptModel prompt, String? path,
      {int? index}) async {
    try {
      final answer = prompt.answer;

      if (answer == null) return false;

      final isMedia = [
        ResponseType.textAudio,
        ResponseType.audio,
        ResponseType.image,
        ResponseType.video,
        ResponseType.imageVideo
      ].contains(prompt.responseType);

      if (isMedia) {
        if (path != null) {
          _deleteFile(path);
          answer.recordings.removeWhere((record) => record.path == path);
        }
      }

      //Removing the response for text questions
      if (index != null &&
          index >= 0 &&
          answer.response != null &&
          index < answer.response!.length) {
        answer.response!.removeAt(index);
      }
      // answer.response = null;
      final updatedPrompt = Prompt.fromModel(prompt.copyWith(answer: answer));
      updatedPrompt.diary.target = diary;
      _promptDAO.updatePrompt(updatedPrompt);
      return true;
    } catch (e, stackTrace) {
      dev.log("Error deleting response: $e",
          name: "Prompt Repository - Remove Response");
      CrashlyticsService().recordError(e, stackTrace,
          reason:
              'Error deleting response in removeResponse - PromptRepository');
      return false;
    }
  }

  _deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Deletes all responses to prompts in the diary.
  /// This function removes all responses to prompts in the diary, effectively clearing the diary of all responses.
  ///
  removeAll() async => _promptDAO.removeAllPrompts();
}
