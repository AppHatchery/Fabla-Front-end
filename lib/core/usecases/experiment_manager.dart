import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';

import 'dart:developer' as dev;

// Default instances for production use
final DiaryRepository _defaultDiaryRepository = DiaryRepository();
final SetupRepository _defaultSetupRepository = SetupRepository();

class ExperimentManager {
  final DiaryRepository _diaryRepository;
  final SetupRepository _setupRepository;

  // Constructor with optional parameters for dependency injection
  ExperimentManager({
    DiaryRepository? diaryRepository,
    SetupRepository? setupRepository,
  })  : _diaryRepository = diaryRepository ?? _defaultDiaryRepository,
        _setupRepository = setupRepository ?? _defaultSetupRepository;

  /// Update Experiment
  Future<bool> update() async {
    try {
      // Get rid of all the data from now till last while keeping all the old data
      final now = DateTime.now();

      final result = _diaryRepository.removeDiariesFrom(now);
      _setupRepository.deleteAllStudies();
      dev.log("Removed diaries: $result");

      // get new content
      final done = await _setupRepository.uploadOnBoardingQuestions();

      return done;
    } catch (e) {
      dev.log(e.toString(), name: 'Experiment Manager Update');
      return false;
    }
  }
}
