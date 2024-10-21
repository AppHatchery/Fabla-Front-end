import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/recording.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
    return model.copyWith(
        answer: prompt.answers.elementAtOrNull(diary.currentEntry));
  }

  Future<List<PromptModel>> loadAll(DiaryModel diary) async{
    final prompts = _promptDAO.getPrompts(id: diary.id);
    final models = prompts.map((prompt) => PromptModel.fromEntity(prompt)).toList();

    final answered = models.map((prompt) {
      return load(diary, prompt.id);}).toList();

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
  bool saveResponse({
    required Diary diary,
    required PromptModel prompt,
    required dynamic response,
    String? type,
  }) {
    // Retrieve the current answer for the prompt
    final answer = prompt.answer;
    // Declare a variable to hold the updated prompt
    late Prompt updatedPrompt;

    // Create a new answer based on the response type
    final newAnswer = type == "audio"
        ? Answer(id: 0, date: DateTime.now()) // Create an audio answer
        : Answer(
            id: 0,
            date: DateTime.now(),
            response: response); // Create a text-based answer

    // If the response type is audio, create a recording and associate it with the new answer
    if (type == "audio") {
      final recording = Recording("Audio Diary", response, "", DateTime.now());
      recording.answer.target = newAnswer;
      newAnswer.recordings.add(recording);
    }

    // If there is no existing answer, update the prompt with the new answer
    if (answer == null) {
      updatedPrompt = Prompt.fromModel(prompt.copyWith(answer: newAnswer));
    }
    // If the response type is audio and there is an existing answer, add a recording to the existing answer
    else if (type == "audio") {
      final recording = Recording("Audio Diary", response, "", DateTime.now());
      recording.answer.target = answer;
      answer.recordings.add(recording);
      updatedPrompt = Prompt.fromModel(prompt.copyWith(answer: answer));
    }
    // If the response type is not audio, update the existing answer with the new response
    else {
      updatedPrompt = Prompt.fromModel(
          prompt.copyWith(answer: answer.copyWith(response: response)));
    }

    // Associate the updated prompt with the specified diary
    updatedPrompt.diary.target = diary;
    // Update the prompt in the data access object
    _promptDAO.updatePrompt(updatedPrompt);

    // Return true to indicate successful saving of the response
    return true;
  }

//TODO: clean implementation - REDO This
  Future<bool> removeResponse(
      Diary diary, PromptModel prompt, String path) async {
    try {
      final answer = prompt.answer;

      if (answer == null) {
        return false;
      }

      //if recording is present, remove it
      if (answer.recordings.isNotEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        final _path = p.join(dir.path, 'recordings', path);

        final file = File(_path);
        await file.delete();
      }

      //update the prompt
      //Removing the recordings
      answer.recordings.clear();

      //Removing the response for text questions
      answer.response = null;
      final updatedPrompt = Prompt.fromModel(prompt.copyWith(answer: answer));
      updatedPrompt.diary.target = diary;
      _promptDAO.updatePrompt(updatedPrompt);
      return true;
    } catch (e) {
      print("Error deleting response: $e");
      return false;
    }
  }
}
