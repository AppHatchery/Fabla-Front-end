import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/questions_entity.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart'
    show CrashlyticsService;
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'dynamic_state.dart';

class DynamicCubit extends Cubit<DynamicState> {
  DynamicCubit() : super(DynamicInitial());
  final setupRepository = SetupRepository();

  void load() async {
    emit(DynamicLoading());
    try {
      final List<Questions> questions =
          await setupRepository.getOnBoardingQuestions();

      if (questions.isNotEmpty) {
        emit(DynamicLoaded(questions: questions));
      } else {
        emit(DynamicUploading());
        // Clean the database first
        setupRepository.clearStudies();
        await setupRepository.getStudies();
        upload(questions.length);
      }
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          reason: "Error fetching Onboarding Questions");
      debugPrint("Error fetching Onboarding Questions: $e");
    }
  }

  Future<int> count() async => await setupRepository
      .getOnBoardingQuestions()
      .then((value) => value.length);

  void save(Questions question, String answer) {
    try {
      final newQuestion = question.copyWith(answer: answer);
      setupRepository
          .saveOnBoardingAnswer(QuestionsEntity.fromModel(newQuestion));
    } catch (e, stackTrace) {
      CrashlyticsService()
          .recordError(e, stackTrace, reason: "Error saving Onboarding Answer");
      debugPrint("Error saving Onboarding Answer: $e");
    }
  }

  void upload(int length) async {
    emit(DynamicUploading());
    try {
      final result = await setupRepository.uploadOnBoardingQuestions();

      if (result == null) {
        return emit(DynamicError(
            "Uh oh, looks like your internet might be slow or disconnected!",
            length));
      }

      if (result) {
        await PreferenceService().setStringPreference(
            key: "onboardingSurveyCompletedDate",
            value: DateTime.now().toString());
        emit(DynamicUploaded(length));
      } else {
        emit(DynamicError("Uh oh, looks like something went wrong!", length));
      }
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          reason: "Error uploading Onboarding Answers");
      debugPrint("Error uploading Onboarding Answers: $e");
    }
  }
}
