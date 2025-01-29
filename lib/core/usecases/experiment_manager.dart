import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';

import 'dart:developer' as dev;

final DiaryRepository _diaryRepository = DiaryRepository();
final SetupRepository _setupRepository = SetupRepository();

// saved version of experiment
final _version = '0.1';

class ExperimentManager {
  Future<bool> checkForUpdate() async {
    // Retrieve version from api
    final version = '0.2';

    return _version != version;
  }

  /// Update Experiment
  Future<bool> update() async {
    try {
      // Get rid of all the data from now till last while keeping all the old data
      dev.log("Let's get the show on the road!");
      final now = DateTime.now();

      final result = _diaryRepository.removeDiariesFrom(now);
      _setupRepository.deleteAllStudies();
      dev.log("Removed diaries: $result");

      // get new content
      // !Overrides diaries that are ongoing, completed and submitted
      await _setupRepository.getStudies();

      return true;
    } catch (e) {
      dev.log(e.toString(), name: 'Experiment Manager Update');
      return false;
    }
  }
}
