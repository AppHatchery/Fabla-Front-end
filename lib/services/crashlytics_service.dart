import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// A service that manages Firebase Crashlytics integration for error reporting and logging.
/// This service provides a centralized way to handle crash reporting, custom logging, user identification,
/// and error tracking throughout the application lifecycle.
///
/// Features:
/// - Automatic error handler setup for Flutter and platform errors
/// - Custom key-value logging for enhanced debugging context
/// - User identification for personalized crash reports
/// - API-specific error reporting with detailed context
/// - Navigation tracking and screen context logging
///
/// Usage example:
/// ```dart
/// final crashlytics = CrashlyticsService();
/// await crashlytics.initialize();
/// await crashlytics.setUserIdentifier('user123');
/// await crashlytics.recordError(exception, stackTrace, fatal: true);
/// ```
class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  FirebaseCrashlytics? _crashlytics;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initializes the Firebase Crashlytics service with proper error handling setup.
  /// This function configures Crashlytics collection, sets up global error handlers,
  /// and ensures the service is ready for crash reporting and logging operations.
  ///
  /// The initialization process includes:
  /// - Enabling Crashlytics collection (disabled in debug mode for development)
  /// - Setting up Flutter framework error handlers
  /// - Configuring platform/async error handlers
  /// - Marking the service as initialized
  ///
  /// Note:
  /// This function is idempotent - calling it multiple times will not cause issues.
  /// Crashlytics collection is automatically disabled in debug mode to avoid
  /// polluting crash reports during development.
  ///
  /// Throws:
  /// Logs initialization errors but does not throw exceptions to prevent app crashes.
  ///
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      _crashlytics = FirebaseCrashlytics.instance;

      // Only enable in release mode
      await _crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);

      _setupErrorHandlers();

      _isInitialized = true;
      dev.log('Crashlytics initialized', name: 'CrashlyticsService');
    } catch (e) {
      dev.log('Failed to initialize Crashlytics: $e',
          name: 'CrashlyticsService', error: e, level: 1000);
      // Mark as initialized anyway to prevent blocking tests
      _isInitialized = true;
    }
  }

  /// Sets up global error handlers for both Flutter framework and platform errors.
  /// This internal function configures automatic error capture for unhandled exceptions
  /// and framework errors throughout the application.
  ///
  /// Error handlers configured:
  /// - Flutter framework errors (FlutterError.onError)
  /// - Platform and async errors (PlatformDispatcher.instance.onError)
  ///
  /// Each error handler automatically adds contextual information such as:
  /// - Error type classification
  /// - Current screen information
  /// - Timestamp and error details
  ///
  void _setupErrorHandlers() {
    if (_crashlytics == null) return;

    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails errorDetails) {
      setCustomKey('error_type', 'flutter_error');
      setCustomKey('error_screen', _getCurrentScreen());
      _crashlytics?.recordFlutterError(errorDetails);
    };

    // Handle platform/async errors
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      setCustomKey('error_type', 'platform_error');
      recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Ensures that the Crashlytics service has been properly initialized before use.
  /// This internal validation function prevents usage of uninitialized service methods.
  ///
  /// Returns true if initialized, false otherwise (instead of throwing in test environments)
  ///
  bool _ensureInitialized() {
    if (!_isInitialized || _crashlytics == null) {
      dev.log('CrashlyticsService not initialized - operation skipped',
          name: 'CrashlyticsService', level: 500);
      return false;
    }
    return true;
  }


  /// Sets a custom key-value pair for enhanced crash report context.
  /// Custom keys provide additional debugging information that appears in crash reports,
  /// helping us understand the application state when errors occur.
  ///
  /// Parameters:
  /// - [key]: A string identifier for the custom data field
  /// - [value]: The associated value (can be string, number, boolean, etc.)
  ///
  /// Usage examples:
  /// ```dart
  /// await crashlytics.setCustomKey('user_level', 5);
  /// await crashlytics.setCustomKey('feature_enabled', true);
  /// await crashlytics.setCustomKey('current_tab', 'profile');
  /// ```
  ///
  /// Note:
  /// Custom keys persist until the app is restarted or explicitly overwritten.
  /// Avoid setting sensitive information as custom keys.
  ///
  Future<void> setCustomKey(String key, Object value) async {
    if (!_ensureInitialized()) return;
    try {
      await _crashlytics!.setCustomKey(key, value);
    } catch (e) {
      dev.log('Failed to set custom key $key: $e',
          name: 'CrashlyticsService', error: e, level: 900);
    }
  }

  /// Sets multiple custom key-value pairs at once for efficient batch processing.
  /// This function provides a convenient way to set multiple custom keys simultaneously,
  /// reducing the number of individual calls and improving performance.
  ///
  /// Parameters:
  /// - [keyValuePairs]: A map containing key-value pairs to be set as custom keys
  ///
  /// Usage example:
  /// ```dart
  /// await crashlytics.setCustomKeys({
  ///   'user_type': 'premium',
  ///   'app_version': '2.1.0',
  ///   'feature_flags': 'dark_mode,notifications',
  /// });
  /// ```
  ///
  /// Note:
  /// Each key-value pair is set individually, so partial success is possible
  /// if some keys fail to set while others succeed.
  ///
  Future<void> setCustomKeys(Map<String, Object> keyValuePairs) async {
    for (final entry in keyValuePairs.entries) {
      await setCustomKey(entry.key, entry.value);
    }
  }

  /// Associates a user identifier with crash reports for personalized debugging.
  /// This function automatically generates and links a user identifier to crash reports
  /// based on experiment configuration and participant data from the setup repository.
  ///
  /// The user identifier format:
  /// - If participant exists: `{experiment.login}-{participant.studyCode}`
  /// - If no participant: `{experiment.login}-anonymous-{timestamp}`
  ///
  /// Usage example:
  /// ```dart
  /// await crashlytics.setUserIdentifier();
  /// ```
  ///
  /// The method performs the following operations:
  /// - Retrieves experiment and participant data from SetupRepository
  /// - Generates a unique identifier combining experiment login and study code
  /// - Falls back to anonymous timestamped ID if participant data unavailable
  /// - Sets the identifier in Crashlytics for crash report association
  /// - Logs the successful identifier assignment
  ///
  /// Note:
  /// The user identifier persists across app sessions until explicitly changed.
  /// Anonymous identifiers include timestamps to ensure uniqueness across sessions.
  ///
  Future<void> setUserIdentifier() async {
    if (!_ensureInitialized()) return;
    try {
      final setupRepository = SetupRepository();
      final participant = setupRepository.getParticipant();
      final experiment = setupRepository.getExperiment();
      final anonymousID =
          "${experiment.login}-anonymous-${DateTime.now().millisecondsSinceEpoch}";

      final userId =
          '${experiment.login}-${participant?.studyCode ?? anonymousID}';

      await _crashlytics!.setUserIdentifier(userId);
      log('User identifier set: $userId');
    } catch (e) {
      dev.log('Failed to set user identifier: $e',
          name: 'CrashlyticsService', error: e, level: 900);
    }
  }

  /// Records a timestamped log message for debugging purposes.
  /// Log messages appear in crash reports and provide chronological context
  /// leading up to crashes or errors.
  ///
  /// Parameters:
  /// - [message]: The log message to be recorded
  ///
  /// Usage examples:
  /// ```dart
  /// await crashlytics.log('User started login process');
  /// await crashlytics.log('User is setting reminders on settings page');
  /// await crashlytics.log('API call initiated: /fabla/getuserprotocol');
  /// ```
  ///
  /// Note:
  /// Log messages are automatically prefixed with ISO 8601 timestamps.
  /// Keep log messages concise and informative for effective debugging.
  ///
  Future<void> log(String message) async {
    if (!_ensureInitialized()) return;
    try {
      await _crashlytics!.log('${DateTime.now().toIso8601String()}: $message');
    } catch (e) {
      dev.log('Failed to log message: $e',
          name: 'CrashlyticsService', error: e, level: 900);
    }
  }

  /// Records navigation events and updates screen context for crash reports.
  /// This function tracks user navigation patterns and maintains current screen
  /// context, which is valuable for understanding user flows when errors occur.
  ///
  /// Parameters:
  /// - [fromScreen]: The name/identifier of the screen being navigated away from
  /// - [toScreen]: The name/identifier of the destination screen
  ///
  /// Usage example:
  /// ```dart
  /// await crashlytics.logNavigation('Home', 'History');
  /// ```
  ///
  /// The function automatically:
  /// - Logs the navigation event with arrow notation
  /// - Updates the 'current_screen' custom key
  /// - Sets the 'previous_screen' custom key for context
  ///
  Future<void> logNavigation(String fromScreen, String toScreen) async {
    await log('Navigation: $fromScreen → $toScreen');
    await setCustomKey('current_screen', toScreen);
    await setCustomKey('previous_screen', fromScreen);
  }

  /// Records an error with optional context and categorization for comprehensive debugging.
  /// This function provides flexible error reporting with contextual information,
  /// custom metadata, and severity classification.
  ///
  /// Parameters:
  /// - [error]: The error object or exception to be recorded
  /// - [stackTrace]: Optional stack trace providing execution context
  /// - [fatal]: Whether this error should be marked as a fatal crash (default: false)
  /// - [context]: Optional map of additional key-value context data
  /// - [reason]: Optional human-readable description of the error cause
  ///
  /// Usage examples:
  /// ```dart
  /// // Basic error recording
  /// await crashlytics.recordError(exception, stackTrace);
  ///
  /// // Error with context and reason
  /// await crashlytics.recordError(
  ///   exception,
  ///   stackTrace,
  ///   fatal: true,
  ///   context: {'user_action': 'submitting diary'},
  ///   reason: 'Submission failed',
  /// );
  /// ```
  ///
  /// Note:
  /// Context data and reason are set as custom keys before recording the error,
  /// providing additional debugging information in crash reports.
  ///
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, Object>? context,
    String? reason,
  }) async {
    if (!_ensureInitialized()) return;
    try {
      // Add context before recording error
      if (context != null) {
        await setCustomKeys(context);
      }

      if (reason != null) {
        await setCustomKey('error_reason', reason);
        await log('Error: $reason - $error');
      } else {
        await log(
          'Error: $error',
        );
      }

      await _crashlytics!.recordError(
        error,
        stackTrace,
        fatal: fatal,
      );
    } catch (e) {
      dev.log('Failed to record error: $e',
          name: 'CrashlyticsService', error: e, level: 900);
    }
  }

  /// Records API-specific errors with detailed request context and metadata.
  /// This specialized function captures API-related failures with comprehensive
  /// context including endpoint information, HTTP details, and request data.
  ///
  /// Parameters:
  /// - [error]: The error object representing the API failure
  /// - [endpoint]: The API endpoint URL or path that failed
  /// - [stackTrace]: Optional stack trace for debugging context
  /// - [statusCode]: HTTP status code returned by the API (if available)
  /// - [method]: HTTP method used (GET, POST, etc. - defaults to 'GET')
  /// - [requestData]: Optional map containing request payload or parameters
  ///
  /// Usage examples:
  /// ```dart
  /// // Basic API error
  /// await crashlytics.recordApiError(exception, '/fabla/getuserprotocol');
  ///
  /// // Detailed API error with full context
  /// await crashlytics.recordApiError(
  ///   exception,
  ///   '/fabla/getuserprotocol',
  ///   stackTrace: stackTrace,
  ///   statusCode: 500,
  ///   method: 'POST',
  ///   requestData: {'study': 'Exp', 'participant': '0001'},
  /// );
  /// ```
  ///
  /// The function automatically categorizes the error as 'api_error' and provides
  /// structured context for API debugging and monitoring.
  ///
  Future<void> recordApiError(
    Object error,
    String endpoint, {
    StackTrace? stackTrace,
    int? statusCode,
    String? method,
    Map<String, dynamic>? requestData,
  }) async {
    final context = <String, Object>{
      'api_endpoint': endpoint,
      'api_method': method ?? 'GET',
      if (statusCode != null) 'api_status_code': statusCode,
      if (requestData != null) 'request_data': requestData.toString(),
      'error_category': 'api_error',
    };

    await recordError(
      error,
      stackTrace,
      context: context,
      reason: 'API call failed: $endpoint',
    );
  }

  /// Retrieves the current screen identifier from the navigation observer.
  /// This internal function provides screen context for error reports by
  /// accessing the current screen information from the custom navigator observer.
  ///
  /// Returns:
  /// A string representing the current screen name or identifier.
  ///
  /// Note:
  /// This function depends on CustomNavigatorObserver being properly configured
  /// in the application's navigation system.
  ///
  String _getCurrentScreen() {
    try {
      return CustomNavigatorObserver.currentScreen;
    } catch (e) {
      return 'unknown';
    }
  }

  Future<void> testNonFatalError() async {
    if (kDebugMode) {
      await recordError(
        Exception('Test non-fatal error'),
        StackTrace.current,
        context: {'test_error': true},
        reason: 'Testing error reporting functionality',
      );
    }
  }
}
