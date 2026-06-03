import 'dart:convert' show jsonDecode;

import 'package:audio_diaries_flutter/core/network/request.dart' show post;
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
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
    try {
      final stored =
          await _preferenceService.getStringPreference(key: updateKey);

      if (stored == UpdateStatus.available.name) return UpdateStatus.available;
      if (stored == UpdateStatus.pending.name) return UpdateStatus.pending;

      final code = _setupRepository.getExperiment();
      final participant = _setupRepository.getParticipant();

      final getdbextras = await post(path: "/fabla/getuserextras", body: {
        'participant_id': participant?.studyCode,
        'login_code': code.login,
      });

      final Map<String, dynamic> json = jsonDecode(getdbextras ?? '{}');
      final List<dynamic>? data = json['data'] as List<dynamic>?;

      if (data == null || data.isEmpty) return UpdateStatus.none;

      final Map<String, dynamic> extra = jsonDecode(data[0]['extra'] as String);
      final acknowledged = extra['protocol_acknowledged'];

      if (acknowledged == null || acknowledged == true) {
        return UpdateStatus.none;
      }

      await setUpdateStatus(UpdateStatus.available);
      return UpdateStatus.available;
    } catch (e, stackTrace) {
      dev.log(e.toString(), name: 'Experiment Manager CheckForUpdates');
      CrashlyticsService().recordError(e, stackTrace,
          reason:
              'Error checking for updates in ExperimentManager.checkForUpdates');
      return UpdateStatus.none;
    }
  }
}
