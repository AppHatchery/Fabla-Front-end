import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/questions_entity.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsInitial());

  final SetupRepository _repository = SetupRepository();

  void load() async {
    emit(SettingsLoading());
    try {
      final questions = await _repository.getOnBoardingQuestions();
      final completedDate = await PreferenceService()
          .getStringPreference(key: "onboardingSurveyCompletedDate");
      final date = completedDate != null
          ? DateTime.parse(completedDate)
          : DateTime.now();
      emit(SettingsLoaded(
          onboardingQuestion: questions, completedDate: formatDateOnly(date)));
    } catch (e) {
      emit(SettingsError("Error fetching Onboarding Questions: $e"));
    }
  }

  void save(Questions question, String answer) async {
    try {
      final newQuestion = question.copyWith(answer: answer);
      _repository.saveOnBoardingAnswer(QuestionsEntity.fromModel(newQuestion));
      await PreferenceService().setStringPreference(
          key: "onboardingSurveyCompletedDate",
          value: DateTime.now().toString());
    } catch (e) {
      emit(SettingsError("Error saving Onboarding Answer: $e"));
    }
  }

  Future<List<Questions>> reload() async {
    final questions = await _repository.getOnBoardingQuestions();
    return questions;
  }
}
