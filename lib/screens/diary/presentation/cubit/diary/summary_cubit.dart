import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/summary_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart'
    show CrashlyticsService;
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:location/location.dart' as l;
import 'dart:async';
import 'dart:developer' as dev;

import '../../../data/diary.dart';

part 'summary_state.dart';

class SummaryCubit extends Cubit<SummaryState> {
  // Modified to support dependency injection for better testability
  // Added constructor parameter for summary repository
  // Default value maintains backward compatibility
  final SummaryRepository _summaryRepository;
  final Map<int, AnswerSubmissionStatus> _submissionStatuses = {};
  final Map<int, Future<bool?>> _activeUploads = {};
  final Map<int, int> _activeUploadGenerations = {};
  final Map<int, int> _promptGenerations = {};
  DiaryModel? _loadedDiary;
  String? _submissionDiaryKey;
  bool _lastUploadHadNoInternet = false;

  // Constructor with optional dependency injection
  // If not provided, uses default implementation for production use
  SummaryCubit({
    SummaryRepository? summaryRepository,
  })  : _summaryRepository = summaryRepository ?? SummaryRepository(),
        super(const SummaryInitial());

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
  Future<void> loadSummary(DiaryModel diary,
      {bool uploadAnswers = false,
      Set<int> resetPromptIds = const <int>{}}) async {
    emit(const SummaryLoading());
    try {
      final value = await _summaryRepository.loadSummary(diary);
      final diaryKey = '${diary.id}:${diary.currentEntry}';
      if (_submissionDiaryKey != diaryKey) {
        for (final promptId in _activeUploads.keys) {
          _promptGenerations[promptId] =
              (_promptGenerations[promptId] ?? 0) + 1;
        }
        _submissionStatuses.clear();
        _submissionDiaryKey = diaryKey;
      }
      for (final promptId in resetPromptIds) {
        _submissionStatuses.remove(promptId);
        _promptGenerations[promptId] = (_promptGenerations[promptId] ?? 0) + 1;
      }
      _loadedDiary = value;

      if (uploadAnswers) {
        for (final prompt in value.prompts.where(_hasAnswer)) {
          _submissionStatuses.putIfAbsent(
              prompt.id, () => AnswerSubmissionStatus.pending);
        }
      }
      _emitLoaded();
      if (uploadAnswers) unawaited(uploadPendingAnswers());
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          reason: 'Error loading summary in loadSummary - SummaryCubit');
      dev.log("Error loading summary: $e", name: "SummaryCubit - loadSummary");
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
  void saveResponse(
      DiaryModel diary, PromptModel prompt, String path, String type,
      {bool uploadAfterSave = false}) {
    try {
      // Updated to use injected repository instance
      _summaryRepository.saveResponse(prompt, path, type);
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          reason: 'Error saving response in saveResponse - SummaryCubit');
      dev.log("Error saving response: $e", name: "SummaryCubit - saveResponse");
    } finally {
      loadSummary(diary,
          uploadAnswers: uploadAfterSave, resetPromptIds: {prompt.id});
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
  void removeResponse(DiaryModel diary, PromptModel prompt, String? path) {
    try {
      // Updated to use injected repository instance
      _summaryRepository.removeResponse(prompt, path).then((value) {
        if (value) {
          _submissionStatuses.remove(prompt.id);
          loadSummary(diary);
        }
      });
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          reason: 'Error removing response in removeResponse - SummaryCubit');
      dev.log("Error deleting response: $e",
          name: "SummaryCubit - removeResponse");
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

  Future<void> submitDiary(DiaryModel diary,
      {bool usePartialUploads = false}) async {
    try {
      if (usePartialUploads) {
        final allUploaded = await uploadPendingAnswers(retryFailed: true);
        if (!allUploaded) {
          emit(_lastUploadHadNoInternet
              ? const SubmitNoInternet()
              : const SubmitError());
          return;
        }
      }
      emit(const SubmitLoading());
      final result = usePartialUploads
          ? await _summaryRepository.submitPartiallyUploadedDiary(diary)
          : await _summaryRepository.submitDiary(diary);
      if (result == null) {
        // Save network error state
        saveNetworkError();
        emit(const SubmitNoInternet());
        return;
      }

      if (result) {
        // Updated to use injected repository instance
        await _summaryRepository.calculateEarnedIncentives(diary);
        resetNetworkError();
        emit(const SummarySubmitted());
      } else {
        emit(const SubmitError());
      }
    } catch (e, stackTrace) {
      dev.log("Error submitting diary: $e", name: "SummaryCubit - submitDiary");
      CrashlyticsService().recordError(e, stackTrace,
          reason: 'Error submitting diary in submitDiary - SummaryCubit');
      emit(const SubmitError());
    }
  }

  Future<bool> uploadPendingAnswers({bool retryFailed = false}) async {
    final diary = _loadedDiary;
    if (diary == null) return false;
    _lastUploadHadNoInternet = false;

    for (final prompt in diary.prompts.where(_hasAnswer)) {
      final status = _submissionStatuses[prompt.id];
      if (status == AnswerSubmissionStatus.successful) continue;
      if (status == AnswerSubmissionStatus.failed && !retryFailed) continue;
      final result = await _uploadPrompt(diary, prompt);
      if (result == null) _lastUploadHadNoInternet = true;
    }

    return diary.prompts.where(_hasAnswer).every((prompt) =>
        _submissionStatuses[prompt.id] == AnswerSubmissionStatus.successful);
  }

  Future<bool?> retryPrompt(int promptId) async {
    final diary = _loadedDiary;
    if (diary == null) return false;
    final prompt =
        diary.prompts.where((item) => item.id == promptId).firstOrNull;
    if (prompt == null || !_hasAnswer(prompt)) return false;
    return _uploadPrompt(diary, prompt);
  }

  Future<bool?> _uploadPrompt(DiaryModel diary, PromptModel prompt) async {
    final generation = _promptGenerations[prompt.id] ?? 0;
    final existing = _activeUploads[prompt.id];
    if (existing != null && _activeUploadGenerations[prompt.id] == generation) {
      return existing;
    }

    final future = _performPromptUpload(diary, prompt, generation);
    _activeUploads[prompt.id] = future;
    _activeUploadGenerations[prompt.id] = generation;
    try {
      return await future;
    } finally {
      if (identical(_activeUploads[prompt.id], future)) {
        _activeUploads.remove(prompt.id);
        _activeUploadGenerations.remove(prompt.id);
      }
    }
  }

  Future<bool?> _performPromptUpload(
      DiaryModel diary, PromptModel prompt, int generation) async {
    _submissionStatuses[prompt.id] = AnswerSubmissionStatus.uploading;
    _emitLoaded();
    final result = await _summaryRepository.submitPrompt(diary, prompt);
    if ((_promptGenerations[prompt.id] ?? 0) != generation) return result;
    _submissionStatuses[prompt.id] = result == true
        ? AnswerSubmissionStatus.successful
        : AnswerSubmissionStatus.failed;
    _emitLoaded();
    return result;
  }

  bool _hasAnswer(PromptModel prompt) {
    final answer = prompt.answer;
    return answer != null &&
        ((answer.response?.isNotEmpty ?? false) ||
            answer.recordings.isNotEmpty);
  }

  void _emitLoaded() {
    final diary = _loadedDiary;
    if (diary == null || isClosed) return;
    emit(SummaryLoaded(diary,
        submissionStatuses: Map<int, AnswerSubmissionStatus>.unmodifiable(
            _submissionStatuses)));
  }

  Future<bool?> checkForLocationPermission() async {
    final extraPermissions = await PreferenceService().getStringListPreference(
          key: 'extra_permissions',
        ) ??
        [];

    if (extraPermissions.contains('location')) {
      // Check if the location permission is granted
      l.Location location = l.Location();
      final granted = await location.hasPermission();
      return granted == l.PermissionStatus.granted;
    }

    return null;
  }

  Future<void> updateDiaryCompletion(DiaryModel diary) async {
    final isAlreadyAvailable =
        diary.completions?.elementAtOrNull(diary.currentEntry);
    if (isAlreadyAvailable == null) {
      final now = DateTime.now();
      final completions = List<DateTime>.from(diary.completions ?? []);
      completions.add(now);
      final newDiary = diary.copyWith(
          id: diary.id,
          studyID: diary.studyID,
          completions: completions,
          submissions: diary.submissions,
          activeDays: diary.activeDays);
      await _summaryRepository.diaryRepository.updateDiary(newDiary);
    }
  }

  void saveNetworkError() async {
    final prefs = PreferenceService();
    await prefs.setBoolPreference(key: 'network_error', value: true);
  }

  resetNetworkError() async {
    final prefs = PreferenceService();
    await prefs.setBoolPreference(key: 'network_error', value: false);
  }
}
