import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/prompt_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/utils/types.dart';
import '../../../data/diary.dart';
import '../../../data/prompt.dart';

part 'prompt_state.dart';

class PromptCubit extends Cubit<PromptState> {
  PromptCubit() : super(const PromptInitial());
  final PromptRepository _repository = PromptRepository();

  /// Loads and updates a prompt's state along with its associated answer, if available.
  ///
  /// This function loads a specific [prompt] using the [repository], which retrieves and
  /// updates the prompt's state by associating it with an answer, if available. If no answers
  /// are found, the prompt's answer is set to `null`. The updated prompt state is then emitted
  /// using the `emit` method, reflecting the loaded state.
  ///
  /// Parameters:
  /// - [prompt]: The prompt to be loaded.
  ///
  /// Usage example:
  /// ```dart
  /// await loadPrompt(myPrompt);
  /// ```
  Future<void> loadPrompt(DiaryModel diary, PromptModel prompt) async {
    try {
      emit(PromptLoading(prompt));
      final newPrompt = _repository.load(diary, prompt.id);
      await Future.delayed(const Duration(microseconds: 1));
      emit(PromptLoaded(newPrompt));
    } catch (e) {
      print("Catch Error: $e");
    }
  }

  /// Saves a user response, handling success, errors, and subsequent prompt loading.
  ///
  /// This function attempts to save a user response based on the provided [prompt]
  /// and recording [path]. It uses the [repository] to perform the saving operation.
  /// If the saving operation is successful, a success modal is displayed using
  /// `showSuccessModal()`. If an error occurs during the operation, a debug message
  /// is printed, and an error modal is shown using `showErrorModal()`. Regardless
  /// of the outcome, the function ensures that the [prompt] is reloaded to reflect
  /// the latest state by calling `loadPrompt()`.
  ///
  /// Parameters:
  /// - [prompt]: The prompt associated with the response.
  /// - [response]: The file path of the recorded response or the selected value.
  ///
  /// Usage example:
  /// ```dart
  /// await saveResponse(myPrompt, '/path/to/recording.wav');
  /// ```
  Future<void> saveResponse(
      {required DiaryModel diary,
      required PromptModel prompt,
      required dynamic response,
      String? type}) async {
    try {
      final saved = _repository.saveResponse(
          diary: Diary.fromModel(diary),
          prompt: prompt,
          response: response,
          type: type);
      if (saved) {
        if (prompt.responseType == ResponseType.recording) {
          showSuccessModal();
        }
      }
    } catch (e) {
      print("Catch Error: $e");
      showErrorModal();
    } finally {
      loadPrompt(diary, prompt);
    }
  }

  /// Removes a user response, handling errors and prompt reloading.
  ///
  /// This function attempts to remove a user response associated with the provided [prompt]
  /// and recording [path]. It utilizes the [repository] to perform the removal operation.
  /// If an error occurs during the operation, a debug message is printed and if necessary the a message is displayed to the user, but the user
  /// experience continues without interruption. Regardless of the outcome, the function
  /// ensures that the [prompt] is reloaded to reflect the latest state by calling `loadPrompt()`.
  ///
  /// Parameters:
  /// - [prompt]: The prompt associated with the response.
  /// - [path]: The file path of the recorded response to be removed.
  ///
  /// Usage example:
  /// ```dart
  /// await removeResponse(myPrompt, '/path/to/recording.wav');
  /// ```
  Future<void> removeResponse(
      {required DiaryModel diary,
      required PromptModel prompt,
      required String path}) async {
    try {
      _repository
          .removeResponse(Diary.fromModel(diary), prompt, path)
          .then((value) {
        if (value) {
          loadPrompt(diary, prompt);
          emit(const PromptResponseDeleted());
        }
      });
    } catch (e) {
      print("Catch Error: $e");
    }
  }

  /// Shows a success modal.
  void showSuccessModal() {
    emit(const PromptResponseSuccess());
  }

  /// Shows an error modal.
  void showErrorModal() {
    emit(const PromptResponseError());
  }
}
