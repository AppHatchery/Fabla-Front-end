import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';

import 'dart:developer' as dev;

// Default instances for production use
final SetupRepository _setupRepository = SetupRepository();

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
      // get new content
      final done = await _setupRepository.uploadOnBoardingQuestions(partialCleanDB: true);

      return done;
    } catch (e) {
      dev.log(e.toString(), name: 'Experiment Manager Update');
      return false;
    }
  }
}
