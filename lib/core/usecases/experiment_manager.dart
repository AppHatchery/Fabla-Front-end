import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';

import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/services/crashlytics_service.dart';

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
      //remove any notifications before running the update
      await _setupRepository.cleanupBeforeUpdate();
      // get new content
      final done = await _setupRepository.uploadOnBoardingQuestions(
          partialCleanDB: true);

      return done;
    } catch (e, stackTrace) {
      dev.log(e.toString(), name: 'Experiment Manager Update');
      CrashlyticsService().recordError(e, stackTrace,
          reason: 'Error updating experiment in ExperimentManager.update');
      return false;
    }
  }
}
