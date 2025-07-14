import 'dart:developer' as dev;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static const String _questionsVersionKey = "question_version";

  static const String _storedVersionKey = "stored_question_version";

  int _localVersion = 1;
  bool _isInitialized = false;

  /// Notifies UI when version changes
  final ValueNotifier<int> versionUpdateCounter = ValueNotifier<int>(1);

  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _localVersion = prefs.getInt(_storedVersionKey) ?? 1;

    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: Duration(minutes: 5),
    ));

    await _remoteConfig.setDefaults({
      _questionsVersionKey: _localVersion,
    });

    try {
      await _remoteConfig.fetchAndActivate();
      // Update local version after successful fetch
      _updateLocalVersion(prefs);

      _remoteConfig.onConfigUpdated.listen((_) async {
        await _remoteConfig.fetchAndActivate();
        _updateLocalVersion(prefs);
      });

      _isInitialized = true;
      debugPrint('RemoteConfig version updated: $_localVersion');
      debugPrint('RemoteConfig initialized successfully');
    } catch (e) {
      debugPrint('RemoteConfig fetch failed: $e');
      // Still mark as initialized even if fetch fails, so we can use defaults
      _isInitialized = true;
    }
  }

  /// Update local version from remote config
  void _updateLocalVersion(SharedPreferences prefs) {
    final fetchedVersion = _remoteConfig.getInt(_questionsVersionKey);

    //compare fetched version with local version
    if (_localVersion != fetchedVersion) {
      debugPrint(
          'RemoteConfig version updated: $_localVersion -> $fetchedVersion');

      // Update local version to the fetched version
      _localVersion = fetchedVersion;
      debugPrint(
          'RemoteConfig version updated 2: $_localVersion -> $fetchedVersion');

      //store the new version in shared preferences
      prefs.setInt(_storedVersionKey, fetchedVersion);
      debugPrint(
          'RemoteConfig version updated 3: $_storedVersionKey -> $fetchedVersion');
      // Call method to get questions based on the new version
      _getQuestions(fetchedVersion);
    }
  }

  /// Called when remote version changes
  void _getQuestions(int version) async {
    debugPrint('Getting Questions from retool');
    try {
      debugPrint('Successfully updated questions');
      versionUpdateCounter.value++; // Notify UI to update
    } catch (e) {
      debugPrint('Error during question update process: $e');
      versionUpdateCounter.value = 0; // Indicate failure
    }
  }

  // Check if service is initialized
  bool get isInitialized => _isInitialized;
}
