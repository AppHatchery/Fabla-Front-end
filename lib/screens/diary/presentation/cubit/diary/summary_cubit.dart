import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/summary_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/diary.dart';

part 'summary_state.dart';

class SummaryCubit extends Cubit<SummaryState> {
  SummaryCubit() : super(const SummaryInitial());
  final SummaryRepository _summaryRepository = SummaryRepository();

  /// Initiates the loading of summary information for a Diary.
  /// This method triggers the loading of summary details for the provided Diary.
  /// It emits a `SummaryLoading` state to signal the start of the loading process,
  /// then uses `_summaryRepository.loadSummary(diary)` to fetch the summary details.
  /// Upon successful loading, a `SummaryLoaded` state is emitted with the loaded summary data.
  ///
  /// Parameters:
  /// - [diary]: The Diary for which summary information is to be loaded.
  ///
  /// Note:
  /// Any exceptions that occur during the loading process are caught and logged, allowing the application to handle potential errors gracefully.
  ///
  void loadSummary(DiaryModel diary) {
    emit(const SummaryLoading());
    try {
      _summaryRepository.loadSummary(diary).then((value) {
        emit(SummaryLoaded(value));
      });
    } catch (e) {
      print("Error loading summary: $e");
    }
  }

  /// Saves a response for a given prompt to a specified path and triggers reloading of summary information.
  /// This method attempts to save a response associated with the provided prompt to the specified path
  /// using the `_summaryRepository.saveResponse(prompt, path)` method. Any potential errors during the saving process are caught and logged.
  /// Regardless of success or failure, it triggers reloading of summary information by calling `loadSummary(diary)`.
  ///
  /// Parameters:
  /// - [diary]: The Diary object related to the prompt for which the response is being saved.
  /// - [prompt]: The Prompt object for which the response is being saved.
  /// - [path]: The path where the response data is to be saved.
  ///
  /// Note:
  /// Any exceptions that occur during the saving process are caught and logged, allowing the application to handle potential errors gracefully.
  ///
  void saveResponse(DiaryModel diary, PromptModel prompt, String path) {
    try {
      _summaryRepository.saveResponse(prompt, path);
    } catch (e) {
      print("Error saving response: $e");
    } finally {
      loadSummary(diary);
    }
  }

  /// Removes a response associated with a given prompt from a specified path and triggers reloading of summary information.
  /// This method attempts to remove the response associated with the provided prompt from the specified path
  /// using the `_summaryRepository.removeResponse(prompt, path)` method. Any potential errors during the removal process are caught and logged.
  /// Regardless of success or failure, it triggers reloading of summary information by calling `loadSummary(diary)`.
  ///
  /// Parameters:
  /// - [diary]: The Diary object related to the prompt for which the response is being removed.
  /// - [prompt]: The Prompt object for which the response is being removed.
  /// - [path]: The path from which the response data is to be removed.
  ///
  /// Note:
  /// Any exceptions that occur during the removal process are caught and logged, allowing the application to handle potential errors gracefully.
  ///
  void removeResponse(DiaryModel diary, PromptModel prompt, String path) {
    try {
      _summaryRepository.removeResponse(prompt, path).then((value) {
        if (value) {
          loadSummary(diary);
        }
      });
    } catch (e) {
      print("Error deleting response: $e");
    }
  }

  /// Initiates the submission of a Diary and triggers reloading of summary information.
  /// This method attempts to submit the provided Diary using the `_summaryRepository.submitDiary(diary)` method.
  /// It emits a `SummarySubmitted` state if the submission is successful.
  /// Regardless of success or failure, it triggers reloading of summary information by calling `loadSummary(diary)`.
  ///
  /// Parameters:
  /// - [diary]: The Diary object to be submitted.
  ///
  /// Note:
  /// Any exceptions that occur during the submission process are caught and logged, allowing the application to handle potential errors gracefully.
  ///
  // void submitDiary(Diary diary) async {
  //   try {
  //     _summaryRepository.submitDiary(diary).then((value) {
  //       if (value) emit(const SummarySubmitted());
  //     });
  //   } catch (e) {
  //     print("Error submitting diary: $e");
  //   } finally {
  //     loadSummary(diary);
  //   }
  // }

  void submitDiary(DiaryModel diary) async {
    try {
      emit(const SubmitLoading());
      final result = await _summaryRepository.submitDiary(diary);
      if (result) {
        emit(const SummarySubmitted());
      } else {
        emit(const SubmitError());
      }
    } catch (e) {
      print("Error submitting diary: $e");
      emit(const SubmitError());
    }
  }
}
