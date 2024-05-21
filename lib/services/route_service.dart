import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/active_dates.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/active_time.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/finish.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/welcome.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:flutter/material.dart';

import '../screens/onboarding/presentation/pages/login.dart';
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

    final setup =
        await PreferenceService().getBoolPreference(key: 'setup') ?? false;
    final notificationAccess = await PreferenceService()
            .getBoolPreference(key: 'notification_requested') ??
        false;
    final remindersSet =
        await PreferenceService().getBoolPreference(key: 'reminders_set') ??
            false;
    final activeDates =
        await PreferenceService().getBoolPreference(key: 'active_dates_seen') ??
            false;
    final micAccess =
        await PreferenceService().getBoolPreference(key: 'mic_requested') ??
            false;
    final setupRepository = SetupRepository();
    final participant = setupRepository.getParticipant();

    if (participant == null) {
      return const LoginPage();
    } else if (participant.name.isEmpty) {
      return const WelcomePage();
    } else if (setup) {
      return const Hub();
    } else if (activeDates == false) {
      return const ActiveDatesPage();
    } else if (remindersSet == false) {
      return const ActiveTimePage();
    } else if (notificationAccess == false) {
      return const NotificationAccessPage();
    } else if (micAccess == false) {
      return const MicAccessPage();
    } else {
      return const FinishPage();
    }
  }
}
