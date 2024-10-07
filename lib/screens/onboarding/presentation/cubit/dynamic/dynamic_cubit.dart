import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/questions_entity.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
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
        await setupRepository.getStudies();
        emit(DynamicNone());
      }
    } catch (e) {
      debugPrint("Error fetching Onboarding Questions: $e");
    }
  }

  Future<int> count () async => await setupRepository.getOnBoardingQuestions().then((value) => value.length);

  void save(Questions question, String answer) {
    try {
      final newQuestion = question.copyWith(answer: answer);
      setupRepository
          .saveOnBoardingAnswer(QuestionsEntity.fromModel(newQuestion));
    } catch (e) {
      debugPrint("Error saving Onboarding Answer: $e");
    }
  }

  void upload() async {
    emit(DynamicUploading());
    try {
      final result = await setupRepository.uploadOnBoardingQuestions();
      if (result) {
        emit(DynamicUploaded());
      } else {
        emit(const DynamicError("Failed to upload answers"));
      }
    } catch (e) {
      debugPrint("Error uploading Onboarding Answers: $e");
    }
  }
}
