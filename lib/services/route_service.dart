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
import 'package:audio_diaries_flutter/services/crashlytics_service.dart'
    show CrashlyticsService;
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:flutter/material.dart';

// import '../screens/onboarding/presentation/pages/login.dart';
import '../screens/onboarding/presentation/pages/mic_access.dart';
import '../screens/onboarding/presentation/pages/notification_access.dart';

class RouteService {
  /// The preference service instance used for preferences.
  /// If not provided, a default instance will be created.
  final PreferenceService _preferenceService;

  /// The setup repository instance used for participant data.
  /// If not provided, a default instance will be created.
  final SetupRepository _setupRepository;

  /// Creates a RouteService with optional dependency injection.
  ///
  /// [preferenceService] can be provided for testing purposes.
  /// [setupRepository] can be provided for testing purposes.
  /// If not provided, default instances will be used.
  RouteService({
    PreferenceService? preferenceService,
    SetupRepository? setupRepository,
  })  : _preferenceService = preferenceService ?? PreferenceService(),
        _setupRepository = setupRepository ?? SetupRepository();

  // Base onboarding sequence. Each step declares its own next/previous so the
  // flow can be traversed forward (navigate) and backward (navigateBack) without
  // a navigation stack.
  //
  // Steps marked type='permission' act as injection points: any strings stored
  // in the 'extra_permissions' preference (e.g. ['microphone', 'camera',
  // 'location']) are inserted immediately after 'notification_access' at
  // runtime. The base flow therefore contains only the one required permission
  // step; optional ones are assembled dynamically in navigate() / navigateBack().
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
    await _preferenceService.setBoolPreference(key: 'cold_start', value: true);

    // Get additional permissions if available
    final extraPermissions = await _preferenceService.getStringListPreference(
          key: 'extra_permissions',
        ) ??
        [];

    // Fetch all preferences concurrently
    final preferences = await Future.wait([
      _preferenceService.getBoolPreference(key: 'setup'),
      _preferenceService.getBoolPreference(key: 'notification_requested'),
      _preferenceService.getBoolPreference(key: 'active_dates_seen'),
      _preferenceService.getBoolPreference(key: 'microphone'),
      _preferenceService.getBoolPreference(key: 'location'),
      _preferenceService.getBoolPreference(key: 'camera'),
      _preferenceService.getBoolPreference(key: 'onboarding_complete'),
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

    final participant = _setupRepository.getParticipant();

    // Priority cascade: each condition represents an incomplete onboarding step.
    // The order matches the _flow sequence — whichever step is not yet marked
    // complete in preferences is where the participant resumes.
    if (setup) {
      await _prepareQuickstartForExistingParticipant();
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

  /// Participants who completed setup before the quickstart walkthrough
  /// existed have no 'has_seen_quickstart' preference. New participants
  /// only reach this method with 'setup' already true on a later cold
  /// start, by which point Hub has already recorded whether they saw it —
  /// so a missing preference here always means an existing installation.
  /// Mark it seen so the modal never surfaces for them. Their quickstart
  /// videos are cached lazily when they visit the Settings tab (see
  /// [Hub]) rather than here, to avoid a Lambda call on every cold start
  /// for participants who never open Settings.
  Future<void> _prepareQuickstartForExistingParticipant() async {
    final hasSeenQuickstart =
        await _preferenceService.getBoolPreference(key: 'has_seen_quickstart');
    if (hasSeenQuickstart != null) return;

    await _preferenceService.setBoolPreference(
        key: 'has_seen_quickstart', value: true);
  }

  Future<dynamic> navigate(dynamic arguments,
      {required BuildContext context, required String current}) async {
    final extraPermissions = await _preferenceService.getStringListPreference(
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
        final repository = _setupRepository;
        final onboardingQuestions = await repository.getOnBoardingQuestions();

        if (context.mounted) {
          if (onboardingQuestions.isNotEmpty) {
            return Navigator.pop(context, true);
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

    final extraPermissions = await _preferenceService.getStringListPreference(
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
        final repository = _setupRepository;
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
        final repository = _setupRepository;
        final onboardingQuestions = await repository.getOnBoardingQuestions();

        // If the onboarding has any question then proceed to that page
        if (onboardingQuestions.isNotEmpty) {
          if (context.mounted) {
            _navigatorTransitionBack(context, const DynamicOnBoardingHub(),
                RouteSettings(name: "/DynamicOnBoardingHub"),
                result: true);
            break;
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

/// A custom Navigator observer that tracks screen navigation events and integrates with Crashlytics.
/// This observer monitors all navigation operations within the Flutter application and maintains
/// a record of current and previous screens for debugging and analytics purposes.
///
/// Features:
/// - Tracks current and previous screen names globally
/// - Automatically logs navigation events to Crashlytics
/// - Handles all types of route operations (push, pop, replace, remove)
/// - Provides fallback screen name extraction for unnamed routes
/// - Static accessors for easy access to screen context from anywhere in the app
///
/// Usage:
/// Add this observer to your MaterialApp or similar:
/// ```dart
/// MaterialApp(
///   navigatorObservers: [CustomNavigatorObserver()],
///   // ... other properties
/// )
///
/// // Access current screen from anywhere:
/// String current = CustomNavigatorObserver.currentScreen;
/// String previous = CustomNavigatorObserver.previousScreen;
/// ```
///
/// Note:
/// This observer automatically integrates with CrashlyticsService to provide
/// navigation context in crash reports and error logs.
///
class CustomNavigatorObserver extends NavigatorObserver {
  static String _currentScreen = 'Unknown';
  static String _previousScreen = 'Unknown';

  /// Get the current screen name
  static String get currentScreen => _currentScreen;

  /// Get the previous screen name
  static String get previousScreen => _previousScreen;

  /// Handles route pop operations when a screen is removed from the navigation stack.
  /// This method is called when the user navigates back or when a route is programmatically
  /// popped from the navigation stack.
  ///
  /// Parameters:
  /// - [route]: The route that was popped/removed from the stack
  /// - [previousRoute]: The route that becomes active after the pop operation
  ///
  /// The method updates the current screen tracking to reflect the navigation change
  /// and logs the event to Crashlytics for debugging purposes.
  ///
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _updateCurrentScreen(previousRoute, route);
    }
  }

  /// Handles route push operations when a new screen is added to the navigation stack.
  /// This method is called when a new screen is navigated to, either through
  /// Navigator.push() or similar navigation methods.
  ///
  /// Parameters:
  /// - [route]: The new route that was pushed onto the navigation stack
  /// - [previousRoute]: The route that was previously active before the push
  ///
  /// The method updates screen tracking to reflect the new current screen
  /// and maintains the previous screen reference for context.
  ///
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _updateCurrentScreen(route, previousRoute);
  }

  /// Handles route replacement operations when one route is substituted for another.
  /// This method is called when a route is replaced in place, such as when using
  /// Navigator.pushReplacement() or similar replacement navigation methods.
  ///
  /// Parameters:
  /// - [newRoute]: The new route that replaces the old route
  /// - [oldRoute]: The route that was replaced and removed from the stack
  ///
  /// The method updates screen tracking to reflect the route replacement
  /// and logs the navigation change to Crashlytics.
  ///
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _updateCurrentScreen(newRoute, oldRoute);
    }
  }

  /// Handles route removal operations when a route is removed from the navigation stack.
  /// This method is called when a route is removed from the stack without being
  /// the top route, such as when removing intermediate routes.
  ///
  /// Parameters:
  /// - [route]: The route that was removed from the navigation stack
  /// - [previousRoute]: The route that remains active after the removal
  ///
  /// The method updates screen tracking if the removal affects the current
  /// active screen and logs the change for debugging purposes.
  ///
  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    if (previousRoute != null) {
      _updateCurrentScreen(previousRoute, route);
    }
  }

  /// Updates the internal screen tracking state and logs navigation events.
  /// This internal method handles the core logic of updating current and previous
  /// screen references, and triggers Crashlytics logging for navigation events.
  ///
  /// Parameters:
  /// - [route]: The route that is becoming the current/active route
  /// - [previousRoute]: The route that was previously active (optional)
  ///
  /// The method performs the following operations:
  /// - Extracts screen names from route objects
  /// - Updates internal state only if screen actually changed
  /// - Maintains previous screen reference for context
  /// - Triggers Crashlytics navigation logging
  ///
  /// Note:
  /// This method includes logic to avoid duplicate logging when the screen
  /// name hasn't actually changed between navigation events.
  ///
  void _updateCurrentScreen(
      Route<dynamic> route, Route<dynamic>? previousRoute) {
    final screenName = _getScreenName(route);
    final previousScreenName =
        previousRoute != null ? _getScreenName(previousRoute) : _previousScreen;

    if (screenName != _currentScreen) {
      _previousScreen = _currentScreen;
      _currentScreen = screenName;

      _logNavigationToCrashlytics(previousScreenName, screenName);
    }
  }

  /// Extracts a human-readable screen name from a Route object.
  /// This method attempts to determine the screen name using multiple fallback strategies
  /// to ensure meaningful screen identification even for routes without explicit names.
  ///
  /// Parameters:
  /// - [route]: The route object from which to extract the screen name
  ///
  /// Returns:
  /// A string representing the screen name. The method uses the following priority:
  /// 1. Route settings name (if explicitly set)
  /// 2. Widget name extracted from MaterialPageRoute string representation
  /// 3. 'UnknownScreen' as final fallback
  ///
  /// Extraction strategies:
  /// - **Named routes**: Uses route.settings.name directly
  /// - **MaterialPageRoute**: Parses route string to extract widget class name
  /// - **Fallback**: Returns 'UnknownScreen' when other methods fail
  ///
  /// Usage example:
  /// ```dart
  /// String screenName = _getScreenName(route);
  /// // Returns: 'ProfileScreen', '/home', 'UnknownScreen', etc.
  /// ```
  ///
  /// Note:
  /// For best results, use named routes or ensure route.settings.name is set
  /// when creating routes. The string parsing fallback is less reliable.
  ///
  String _getScreenName(Route<dynamic> route) {
    if (route.settings.name != null && route.settings.name!.isNotEmpty) {
      return route.settings.name!;
    }

    // Fall back to trying to extract from route type
    final routeStr = route.toString();
    if (routeStr.contains('MaterialPageRoute')) {
      // Try to extract widget name from MaterialPageRoute
      final match =
          RegExp(r'MaterialPageRoute<.*?>\((.*?)\)').firstMatch(routeStr);
      if (match != null) {
        return match.group(1)?.split('(').first ?? 'UnknownScreen';
      }
    }

    return 'UnknownScreen';
  }

  /// Logs navigation events to the Crashlytics service for debugging and analytics.
  /// This internal method creates a bridge between the navigation observer and
  /// the Crashlytics service, ensuring all navigation events are recorded.
  ///
  /// Parameters:
  /// - [from]: The name of the screen being navigated away from
  /// - [to]: The name of the destination screen
  ///
  /// The method calls CrashlyticsService.logNavigation() to record:
  /// - Navigation flow information (from → to)
  /// - Updated current/previous screen context
  /// - Timestamped navigation logs
  ///
  /// Note:
  /// This method assumes CrashlyticsService is properly initialized.
  /// Navigation logging will fail silently if Crashlytics is not available.
  ///
  void _logNavigationToCrashlytics(String from, String to) {
    CrashlyticsService().logNavigation(from, to);
  }
}
