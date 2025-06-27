import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';

import 'dart:developer' as dev;

class ExperimentManager {
  // Modified to support dependency injection for better testability
  // Added constructor parameter for setup repository
  // Default value maintains backward compatibility
  final SetupRepository _setupRepository;

  // Constructor with optional dependency injection
  // If not provided, uses default implementation for production use
  ExperimentManager({
    SetupRepository? setupRepository,
  }) : _setupRepository = setupRepository ?? SetupRepository();

  /// Update Experiment
  Future<bool> update() async {
    try {
      // get new content
      final done = await _setupRepository.uploadOnBoardingQuestions(
          partialCleanDB: true);

      return done;
    } catch (e) {
      dev.log(e.toString(), name: 'Experiment Manager Update');
      return false;
    }
  }
}
