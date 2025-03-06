import 'dart:io';

import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'dart:developer' as dev;

import '../../../../core/database/dao/answer_dao.dart';
import '../../../../main.dart';
import '../../../../objectbox.g.dart';
import '../../data/prompt.dart';
import '../entities/answer.dart';
import '../entities/recording.dart';

class AnswerRepository {
  AnswerDAO dao = AnswerDAO(box: Box<Answer>(objectbox.store));

  /// Loads a prompt along with its associated answer, if available.
  ///
  /// This function loads a specific [prompt] and retrieves its associated answers from the
  /// data access object ([dao]). If no answers are found, the prompt is updated with a `null` answer.
  /// If answers are available, the first answer is associated with the prompt. The updated prompt
  /// is returned, reflecting the loaded state.
  ///
  /// Parameters:
  /// - [prompt]: The prompt to be loaded.
  ///
  /// Returns:
  /// - An updated [PromptModel] instance reflecting the loaded state.
  ///
  /// Usage example:
  /// ```dart
  /// final loadedPrompt = await load(myPrompt);
  /// ```
  Future<PromptModel> load(PromptModel prompt) async {
    final answers = dao.getAnswers(prompt.id);
    answers.forEach((element) {
      final prompt = element.prompt.target;
      dev.log("Prompt id: ${prompt?.id}| Prompt question: ${prompt?.question}",
          name: 'Answer Repository - Load');
      dev.log("Answer: ${element.response}", name: 'Answer Repository - Load');
    });

    // Determine the updated prompt based on whether answers are available
    final updatedPrompt = answers.isEmpty
        ? prompt.copyWith(answer: null)
        : prompt.copyWith(answer: answers.first);
    updatedPrompt.id = prompt.id;
    return updatedPrompt; // Return the updated prompt
  }

  /// Saves a new response or updates an existing response associated with a prompt.
  ///
  /// This function creates a new response or updates an existing one based on the provided [prompt].
  /// If the [prompt] already has an associated answer, the function updates that answer by adding a new
  /// recording specified by the [path]. If there is no existing answer, a new answer is created and
  /// associated with the prompt. The recording is added to the newly created or updated answer.
  ///
  /// Parameters:
  /// - [prompt]: The prompt instance associated with the response.
  /// - [response]: The file path of the recording to be saved or the selected value.
  ///
  /// Returns:
  /// - A boolean indicating the success of the save operation.
  ///
  /// Usage example:
  /// ```dart
  /// final saved = await saveResponse(myPrompt, '/path/to/recording.wav');
  /// ```
  Future<bool> saveResponse(
      {required PromptModel prompt,
      required dynamic response,
      required String type}) async {
    final isUpdating = prompt.answer != null;
    late Answer answer;

    if (type == 'audio' || type == 'image' || type == 'video') {
      answer = isUpdating
          ? prompt.answer! // Use the existing answer for updating
          : Answer(id: 0, date: DateTime.now()); // Create a new answer
      // Create a new recording and associate it with the answer
      final recording =
          Recording(prompt.question, response, type, null, DateTime.now());
      recording.answer.target = answer;
      answer.recordings.add(recording);
    } else {
      answer = isUpdating
          ? prompt.answer!.copyWith(response: response)
          : Answer(
              id: 0,
              //promptId: prompt.id,
              date: DateTime.now(),
              response: response);
    }

    // Add or update the answer in the database
    dao.addResponse(answer);

    return true; // Indicate successful save
  }

  /// Removes a recording associated with a prompt's answer and updates the answer's state if needed.
  ///
  /// This function handles the removal of a recording file specified by the provided [path].
  /// It first deletes the corresponding file from the file system. If the [prompt] has an associated
  /// answer and the recording's path matches one in the answer's recordings, the recording is removed
  /// from the answer's recordings list. If the recordings list becomes empty as a result, the answer
  /// may either be updated or removed based on the situation.
  ///
  /// Parameters:
  /// - [prompt]: The prompt instance associated with the recording.
  /// - [path]: The file path of the recording to be removed.
  ///
  /// This function operates asynchronously and catches any errors that might occur during the process,
  /// printing debug information for troubleshooting.
  ///
  /// Usage example:
  /// ```dart
  /// await removeResponse(myPrompt, '/path/to/recording.wav');
  /// ```
  Future<void> removeResponse(PromptModel prompt, String? path) async {
    try {
      final answer = prompt.answer;

      if (answer == null) return;

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
      answer.response = null;
      dao.updateResponse(answer);
    } catch (e) {
      dev.log("Catch Error: $e", name: 'Answer Repository - Remove Response');
    }
  }

  _deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  removeAllResponses() {
    dao.removeAll();
  }
}
