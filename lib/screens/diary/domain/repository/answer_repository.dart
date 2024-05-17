import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
      print("Prompt id: ${prompt?.id}| Prompt question: ${prompt?.question}");
      print("Answer: ${element.response}");
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
      String? type}) async {
    final isUpdating = prompt.answer != null;
    late Answer answer;

    if (type == 'audio') {
      answer = isUpdating
          ? prompt.answer! // Use the existing answer for updating
          : Answer(id: 0, date: DateTime.now()); // Create a new answer
      // Create a new recording and associate it with the answer
      final recording =
          Recording("Audio Diary", response, null, DateTime.now());
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
  Future<void> removeResponse(PromptModel prompt, String path) async {
    final answer = prompt.answer;
    try {
      if (prompt.answer?.recordings.isEmpty ?? true) {
        prompt.answer!.response = "";
        if (prompt.answer != null) {
          dao.updateResponse(answer!);
        }
      } else {
        // Delete the recording file from the file system
        final dir = await getApplicationDocumentsDirectory();
        final _path = p.join(dir.path, 'recordings', path);

        final file = File(_path);
        await file.delete();

        if (answer != null) {
          // Remove the recording from the answer's recordings list
          answer.recordings.removeWhere((recording) => recording.path == path);

          dao.updateResponse(answer);
        }
      }
    } catch (e) {
      print("Catch Error: $e");
    }
  }
}
