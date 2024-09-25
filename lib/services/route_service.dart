import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/active_dates.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/dynamic_page.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/finish.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/study_login.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/welcome.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:flutter/material.dart';

// import '../screens/onboarding/presentation/pages/login.dart';
import '../screens/onboarding/presentation/pages/mic_access.dart';
import '../screens/onboarding/presentation/pages/notification_access.dart';

class RouteService {
  /// Determines the appropriate route based on the participant's status.
  ///
  /// This function is responsible for determining the route that should be displayed
  /// based on the participant's status. It checks whether a participant exists and
  /// whether the participant's name is empty to decide whether to navigate to the
  /// login page, the welcome page, or the hub page.
  ///
  /// Returns:
  /// - An appropriate widget representing the route to be displayed.
  ///
  /// Example usage within a `MaterialApp` or `CupertinoApp`:
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return MaterialApp(
  ///     // ...
  ///     initialRoute: '/',
  ///     routes: {
  ///       '/': (context) => getRoute(),
  ///     },
  ///   );
  /// }
  /// ```
  Future<Widget> getRoute() async {
    await PreferenceService().setBoolPreference(key: 'cold_start', value: true);

    // Fetch all preferences concurrently
    final preferences = await Future.wait([
      PreferenceService().getBoolPreference(key: 'setup'),
      PreferenceService().getBoolPreference(key: 'notification_requested'),
      PreferenceService().getBoolPreference(key: 'active_dates_seen'),
      PreferenceService().getBoolPreference(key: 'mic_requested'),
      PreferenceService().getBoolPreference(key: 'onboarding_complete'),
    ]);

    final setup = preferences[0] ?? false;
    final notificationAccess = preferences[1] ?? false;
    final activeDates = preferences[2] ?? false;
    final micAccess = preferences[3] ?? false;
    final onboardingComplete = preferences[4] ?? false;

    final setupRepository = SetupRepository();
    final participant = setupRepository.getParticipant();

    if (setup) {
      return const Hub();
    }
    if (participant == null) {
      return const StudyLogin();
    }
    if (participant.name.isEmpty) {
      return const WelcomePage();
    }
    if (!micAccess) {
      return const MicAccessPage();
    }
    if (!notificationAccess) {
      return const NotificationAccessPage();
    }
    if (!onboardingComplete) {
      return const DynamicOnBoardingHub();
    }
    if (!activeDates) {
      return const ActiveDatesPage();
    }
    return const FinishPage();
  }
}
