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
    {'route': 'login', 'next': 'confirm', 'type': 'login', 'previous': ''},
    {
      'route': 'confirm',
      'next': 'participant_login',
      'type': 'info',
      'previous': 'login'
    },
    {
      'route': 'participant_login',
      'next': 'welcome',
      'type': 'login',
      'previous': 'confirm'
    },
    {
      'route': 'welcome',
      'next': 'participant_details',
      'type': 'info',
      'previous': 'participant_login'
    },
    {
      'route': 'participant_details',
      'next': 'notification_access',
      'type': 'data',
      'previous': 'welcome',
    },
    {
      'route': 'notification_access',
      'next': 'dynamic_onboarding',
      'type': 'permission',
      'previous': 'participant_details',
    },
    {
      'route': 'dynamic_onboarding',
      'next': 'active_dates',
      'type': 'data',
      'previous': 'notification_access',
    },
    {
      'route': 'active_dates',
      'next': 'finish',
      'type': 'info',
      'previous': 'dynamic_onboarding'
    },
    {
      'route': 'finish',
      'next': 'hub',
      'type': 'info',
      'previous': 'active_dates'
    },
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

  Future<dynamic> navigateBack(
      {required BuildContext context, required String current}) async {
    // If the app has routes present
    if (context.mounted && Navigator.canPop(context)) {
      if (current == "active_dates") {
        final repository = SetupRepository();
        final onboardingQuestions = await repository.getOnBoardingQuestions();

        if (context.mounted) {
          if (onboardingQuestions.isNotEmpty) {
            return Navigator.pop(context);
          }

          return Navigator.popUntil(
              context,
              (route) =>
                  route.settings.name != "/DynamicOnBoardingHub" &&
                  route.settings.name != "/ActiveDatesPage");
        }
      }

      if (context.mounted) return Navigator.pop(context);
    }

    final extraPermissions = await PreferenceService().getStringListPreference(
          key: 'extra_permissions',
        ) ??
        [];

    // Construct full flow with extra permissions included (as in original)
    final flow = <Map<String, String>>{};

    for (final f in _flow) {
      flow.add(f);
      if (f['type'] == 'permission') {
        for (int i = 0; i < extraPermissions.length; i++) {
          final permission = extraPermissions[i];
          final nextPermission = extraPermissions.elementAtOrNull(i + 1);
          final step = {
            'route': permission,
            'next': nextPermission ?? f['next']!,
            'previous': f['route']!,
            'type': 'permission'
          };
          if (f['route'] == 'notification_access') {
            flow.remove(f);
            flow.add({
              'route': f['route']!,
              'next': permission,
              'previous': f['previous']!,
              'type': 'permission'
            });
          }
          if (!flow.any((s) => s['route'] == permission)) flow.add(step);
        }
      }
    }

    // Find the previous step in the flow
    final previousStep = flow.firstWhere(
      (element) => element['next'] == current,
      orElse: () => {},
    );
    switch (previousStep['route']) {
      case 'login':
        if (context.mounted) {
          _navigatorTransitionBack(
              context, const StudyLogin(), RouteSettings(name: "/StudyLogin"));
        }
        break;
      case 'confirm':
        final repository = SetupRepository();
        final experiment = repository.getExperiment();

        if (context.mounted) {
          _navigatorTransitionBack(
              context,
              ConfirmJoiningPage(experiment: experiment),
              RouteSettings(name: "/ConfirmJoiningPage"));
        }
        break;
      case 'participant_login':
        if (context.mounted) {
          _navigatorTransitionBack(
              context, const LoginPage(), RouteSettings(name: "/LoginPage"));
        }
        break;
      case 'welcome':
        if (context.mounted) {
          _navigatorTransitionBack(context, const WelcomePage(),
              RouteSettings(name: "/WelcomePage"));
        }
        break;
      case 'participant_details':
        if (context.mounted) {
          _navigatorTransitionBack(context, const ParticipantDetailsPage(),
              RouteSettings(name: "/ParticipantDetailsPage"));
        }
        break;
      case 'notification_access':
        if (context.mounted) {
          _navigatorTransitionBack(context, const NotificationAccessPage(),
              RouteSettings(name: "/NotificationAccessPage"));
        }
        break;
      case 'dynamic_onboarding':
        final repository = SetupRepository();
        final onboardingQuestions = await repository.getOnBoardingQuestions();

        // If the onboarding has any question then proceed to that page
        if (onboardingQuestions.isNotEmpty) {
          if (context.mounted) {
            _navigatorTransitionBack(context, const DynamicOnBoardingHub(),
                RouteSettings(name: "/DynamicOnBoardingHub"),
                result: true);
          }
        }
        // If not then we proceed to the page before that
        if (context.mounted) {
          navigateBack(context: context, current: 'dynamic_onboarding');
        }
        break;
      case 'active_dates':
        if (context.mounted) {
          _navigatorTransitionBack(context, const ActiveDatesPage(),
              RouteSettings(name: "/ActiveDatesPage"));
        }
        break;
      case 'finish':
        if (context.mounted) {
          _navigatorTransitionBack(
              context, const FinishPage(), RouteSettings(name: "/FinishPage"));
        }
        break;
      case 'location':
        if (context.mounted) {
          _navigatorTransitionBack(context, const LocationAccess(),
              RouteSettings(name: "/LocationAccess"));
        }
        break;
      case 'microphone':
        if (context.mounted) {
          _navigatorTransitionBack(context, const MicAccessPage(),
              RouteSettings(name: "/MicAccessPage"));
        }
        break;
      case 'camera':
        if (context.mounted) {
          _navigatorTransitionBack(context, const CameraAccess(),
              RouteSettings(name: "/CameraAccess"));
        }
        break;
    }
  }

  /// Navigates to the target page with a slide transition to mimic going back.
  /// Target page is the page to navigate to.
  /// Settings are the route settings for the page.
  void _navigatorTransitionBack(
      BuildContext context, Widget targetPage, RouteSettings settings,
      {bool? result}) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        settings: settings,
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
      result: result,
    );
  }
}
