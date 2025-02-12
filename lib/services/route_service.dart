import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/active_dates.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/camera_access.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/confirm.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/dynamic_page.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/finish.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/location_access.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/login.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/participant_details.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/study_login.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/welcome.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:flutter/material.dart';

// import '../screens/onboarding/presentation/pages/login.dart';
import '../screens/onboarding/presentation/pages/mic_access.dart';
import '../screens/onboarding/presentation/pages/notification_access.dart';

class RouteService {
  // Main Flow for the onboarding process without any extra permissions
  final List<Map<String, String>> _flow = [
    {'route': 'login', 'next': 'confirm', 'type': 'login'},
    {'route': 'confirm', 'next': 'participant_login', 'type': 'info'},
    {'route': 'participant_login', 'next': 'welcome', 'type': 'login'},
    {'route': 'welcome', 'next': 'participant_details', 'type': 'info'},
    {'route': 'participant_details', 'next': 'mic_access', 'type': 'data'},
    {
      'route': 'mic_access',
      'next': 'notification_access',
      'type': 'permission'
    },
    {
      'route': 'notification_access',
      'next': 'dynamic_onboarding',
      'type': 'permission'
    },
    {'route': 'dynamic_onboarding', 'next': 'active_dates', 'type': 'data'},
    {'route': 'active_dates', 'next': 'finish', 'type': 'info'},
    {'route': 'finish', 'next': 'hub', 'type': 'info'},
  ];

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

    // Get additional permissions if available
    final extraPermissions = await PreferenceService().getStringListPreference(
          key: 'extra_permissions',
        ) ??
        [];

    // Fetch all preferences concurrently
    final preferences = await Future.wait([
      PreferenceService().getBoolPreference(key: 'setup'),
      PreferenceService().getBoolPreference(key: 'notification_requested'),
      PreferenceService().getBoolPreference(key: 'active_dates_seen'),
      PreferenceService().getBoolPreference(key: 'mic_requested'),
      PreferenceService().getBoolPreference(key: 'location'),
      PreferenceService().getBoolPreference(key: 'camera'),
      PreferenceService().getBoolPreference(key: 'onboarding_complete'),
    ]);

    final setup = preferences[0] ?? false;
    final notificationAccess = preferences[1] ?? false;
    final activeDates = preferences[2] ?? false;
    final micAccess = preferences[3] ?? false;
    final locationAccess = extraPermissions.contains('location')
        ? (preferences[4] ?? false)
        : true;
    final cameraAccess =
        extraPermissions.contains('camera') ? (preferences[5] ?? false) : true;
    final onboardingComplete = preferences[6] ?? false;

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
    if (!cameraAccess) {
      return const CameraAccess();
    }
    if (!locationAccess) {
      return const LocationAccess();
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

  Future<dynamic> navigate(dynamic arguments,
      {required BuildContext context, required String current}) async {
    final extraPermissions = await PreferenceService().getStringListPreference(
          key: 'extra_permissions',
        ) ??
        [];

    //add extra permissions to the flow
    final flow = <Map<String, String>>{}; // Set to avoid duplicates

    for (final f in _flow) {
      flow.add(f);
      if (f['type'] == 'permission') {
        for (int i = 0; i < extraPermissions.length; i++) {
          final permission = extraPermissions[i];
          final nextPermission = extraPermissions.elementAtOrNull(i + 1);
          final step = {
            'route': permission,
            'next': nextPermission ?? f['next']!,
            'type': 'permission'
          };
          if (f['route'] == 'mic_access') {
            flow.remove(f);
            flow.add({
              'route': f['route']!,
              'next': permission,
              'type': 'permission'
            });
          }
          if (!flow.any((step) => step['route'] == permission)) flow.add(step);
        }
      }
    }

    final next =
        flow.firstWhere((element) => element['route'] == current)['next'];

    switch (next) {
      case 'login':
        if (context.mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const StudyLogin()));
        }
        break;
      case 'confirm':
        final experiment = arguments as ExperimentModel;
        if (context.mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ConfirmJoiningPage(
                        experiment: experiment,
                      )));
        }
        break;
      case 'participant_login':
        if (context.mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const LoginPage()));
        }
        break;
      case 'welcome':
        if (context.mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const WelcomePage()));
        }
        break;
      case 'participant_details':
        if (context.mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ParticipantDetailsPage()));
        }
        break;
      case 'mic_access':
        if (context.mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const MicAccessPage()));
        }
        break;
      case 'notification_access':
        if (context.mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NotificationAccessPage()));
        }
        break;
      case 'dynamic_onboarding':
        if (context.mounted) {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const DynamicOnBoardingHub()));
        }
        break;
      case 'active_dates':
        if (context.mounted) {
          return Navigator.push(context,
              MaterialPageRoute(builder: (context) => const ActiveDatesPage()));
        }
        break;
      case 'finish':
        if (context.mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const FinishPage()));
        }
        break;
      case 'hub':
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Hub()),
              (route) => false);
        }

        break;
      case 'camera':
        if (context.mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const CameraAccess()));
        }
        break;
      case 'location':
        if (context.mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const LocationAccess()));
        }
      default:
        if (context.mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const StudyLogin()));
        }
    }
  }
}
