import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';

import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';

class ExperimentManager {
  // Modified to support dependency injection for better testability
  // Added constructor parameter for setup repository
  // Default value maintains backward compatibility
  final SetupRepository _setupRepository;

  final PreferenceService _preferenceService;

  static String updateKey = 'experiment_update_available';

  // Constructor with optional dependency injection
  // If not provided, uses default implementation for production use
  ExperimentManager({
    SetupRepository? setupRepository,
    PreferenceService? preferenceService,
  })  : _setupRepository = setupRepository ?? SetupRepository(),
        _preferenceService = preferenceService ?? PreferenceService();

  /// Update Experiment
  Future<bool> update() async {
    try {
      // get new content
      final done = await _setupRepository.uploadOnBoardingQuestions(
          partialCleanDB: true);

      if (done == null) {
        return false;
      }

      return done;
    } catch (e, stackTrace) {
      dev.log(e.toString(), name: 'Experiment Manager Update');
      CrashlyticsService().recordError(e, stackTrace,
          reason: 'Error updating experiment in ExperimentManager.update');
      return false;
    }
  }

  /// Persist the current update status to shared preferences.
  Future<void> setUpdateStatus(UpdateStatus status) async {
    await _preferenceService.setStringPreference(
      key: updateKey,
      value: status.name,
    );
  }

  /// Check for updates
  Future<UpdateStatus> checkForUpdates() async {
    // get shared preferences stored bool
    final available =
        await _preferenceService.getStringPreference(key: updateKey) ?? 'available';

    if (available == 'available') {
      // trigger the update pop up in the UI
      return UpdateStatus.available;
    } else if (available == 'pending') {
      // Handle pending update
      return UpdateStatus.pending;
    }

    return UpdateStatus.none;
  }
}

enum UpdateStatus { none, available, pending }
