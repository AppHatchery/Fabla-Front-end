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
    {'route': 'login', 'next': 'confirm', 'previous': '', 'type': 'login'},
    {
      'route': 'confirm',
      'next': 'participant_login',
      'previous': 'login',
      'type': 'info'
    },
    {
      'route': 'participant_login',
      'next': 'welcome',
      'previous': 'confirm',
      'type': 'login'
    },
    {
      'route': 'welcome',
      'next': 'participant_details',
      'previous': 'participant_login',
      'type': 'info'
    },
    {
      'route': 'participant_details',
      'next': 'notification_access',
      'previous': 'welcome',
      'type': 'data'
    },
    {
      'route': 'notification_access',
      'next': 'dynamic_onboarding',
      'previous': 'participant_details',
      'type': 'permission'
    },
    {
      'route': 'dynamic_onboarding',
      'next': 'active_dates',
      'previous': 'notification_access',
      'type': 'data'
    },
    {
      'route': 'active_dates',
      'next': 'finish',
      'previous': 'dynamic_onboarding',
      'type': 'info'
    },
    {
      'route': 'finish',
      'next': 'hub',
      'previous': 'active_dates',
      'type': 'info'
    },
  ];

  // Navigate back

  void navigateBackTo(BuildContext context, Widget targetPage) {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
  }

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

// save current route and set it to the last route and retrieve it
    final lastRoute =
        await PreferenceService().getStringPreference(key: 'last_route');
    if (lastRoute != null) {
      return _getWidgetForRoute(lastRoute);
    }

    // Fetch all preferences concurrently
    final preferences = await Future.wait([
      PreferenceService().getBoolPreference(key: 'setup'),
      PreferenceService().getBoolPreference(key: 'notification_requested'),
      PreferenceService().getBoolPreference(key: 'active_dates_seen'),
      PreferenceService().getBoolPreference(key: 'microphone'),
      PreferenceService().getBoolPreference(key: 'location'),
      PreferenceService().getBoolPreference(key: 'camera'),
      PreferenceService().getBoolPreference(key: 'onboarding_complete'),
    ]);

    final setup = preferences[0] ?? false;
    final notificationAccess = preferences[1] ?? false;
    final activeDates = preferences[2] ?? false;
    final micAccess = extraPermissions.contains('microphone')
        ? (preferences[3] ?? false)
        : true;
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
    if (!notificationAccess) {
      return const NotificationAccessPage();
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
          // Notification access is the anchor for the extra permissions (if any)
          // The notification permission is the only permission that is not optional
          if (f['route'] == 'notification_access') {
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
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const StudyLogin(),
                  settings: RouteSettings(name: "/StudyLogin")));
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
                      ),
                  settings: RouteSettings(name: "/ConfirmJoiningPage")));
        }
        break;
      case 'participant_login':
        if (context.mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                  settings: RouteSettings(name: "/LoginPage")));
        }
        break;
      case 'welcome':
        if (context.mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const WelcomePage(),
                  settings: RouteSettings(name: "/WelcomePage")));
        }
        break;
      case 'participant_details':
        if (context.mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ParticipantDetailsPage(),
                  settings: RouteSettings(name: "/ParticipantDetailsPage")));
        }
        break;
      case 'microphone':
        if (context.mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const MicAccessPage(),
                  settings: RouteSettings(name: "/MicAccessPage")));
        }
        break;
      case 'notification_access':
        if (context.mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NotificationAccessPage(),
                  settings: RouteSettings(name: "/NotificationAccessPage")));
        }
        break;
      case 'dynamic_onboarding':
        if (context.mounted) {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const DynamicOnBoardingHub(),
                  settings: RouteSettings(name: "/DynamicOnBoardingHub")));
        }
        break;
      case 'active_dates':
        if (context.mounted) {
          return Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ActiveDatesPage(),
                  settings: RouteSettings(name: "/ActiveDatesPage")));
        }
        break;
      case 'finish':
        if (context.mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const FinishPage(),
                  settings: RouteSettings(name: "/FinishPage")));
        }
        break;
      case 'hub':
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const Hub(),
                  settings: RouteSettings(name: "/Hub")),
              (route) => false);
        }

        break;
      case 'camera':
        if (context.mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CameraAccess(),
                  settings: RouteSettings(name: "/CameraAccess")));
        }
        break;
      case 'location':
        if (context.mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const LocationAccess(),
                  settings: RouteSettings(name: "/LocationAccess")));
        }
      default:
        if (context.mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const StudyLogin(),
                  settings: RouteSettings(name: "/StudyLogin")));
        }
    }
  }
}

Widget _getWidgetForRoute(String route) {
  switch (route) {
    case 'login':
      return const StudyLogin();
    case 'participant_login':
      return const LoginPage();
    case 'welcome':
      return const WelcomePage();
    case 'participant_details':
      return const ParticipantDetailsPage();
    case 'notification_access':
      return const NotificationAccessPage();
    case 'dynamic_onboarding':
      return const DynamicOnBoardingHub();
    case 'active_dates':
      return const ActiveDatesPage();
    case 'finish':
      return const FinishPage();
    case 'hub':
      return const Hub();
    case 'camera':
      return const CameraAccess();
    case 'location':
      return const LocationAccess();
    default:
      return const StudyLogin();
  }
}
