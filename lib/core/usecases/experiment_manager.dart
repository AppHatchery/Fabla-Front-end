import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';

import 'dart:developer' as dev;

final SetupRepository _setupRepository = SetupRepository();

class ExperimentManager {
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
