import 'package:audio_diaries_flutter/core/secrets/keys.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:pendo_sdk/pendo_sdk.dart';
import 'dart:developer' as dev;

const String _testID = "Test";

/// Interface for Pendo plugin to enable dependency injection for testing.
abstract class IPendoPlugin {
  Future<void> setup(String pendoKey);
  Future<void> startSession(String visitorId, String accountId,
      Map<String, dynamic>? visitorData, Map<String, dynamic>? accountData);
  Future<void> endSession();
  Future<void> track(String eventName, Map<String, dynamic>? properties);
}

/// Wrapper class that implements IPendoPlugin and delegates to PendoFlutterPlugin.
class PendoPluginWrapper implements IPendoPlugin {
  @override
  Future<void> setup(String pendoKey) async {
    await PendoFlutterPlugin.setup(pendoKey);
  }

  @override
  Future<void> startSession(
      String visitorId,
      String accountId,
      Map<String, dynamic>? visitorData,
      Map<String, dynamic>? accountData) async {
    await PendoFlutterPlugin.startSession(
        visitorId, accountId, visitorData, accountData);
  }

  @override
  Future<void> endSession() async {
    await PendoFlutterPlugin.endSession();
  }

  @override
  Future<void> track(String eventName, Map<String, dynamic>? properties) async {
    await PendoFlutterPlugin.track(eventName, properties);
  }
}

class PendoService {
  /// Static instance of IPendoPlugin for dependency injection.
  /// Can be overridden for testing purposes.
  static IPendoPlugin _plugin = PendoPluginWrapper();

  /// Sets a custom IPendoPlugin instance for testing.
  /// This method allows tests to inject a mock instance.
  static void setPluginForTesting(IPendoPlugin plugin) {
    _plugin = plugin;
  }

  /// Resets the IPendoPlugin instance to the default.
  /// Used to clean up after tests.
  static void resetPlugin() {
    _plugin = PendoPluginWrapper();
  }

  /// Initializes the Pendo Flutter plugin with the given Pendo key.
  ///
  /// This function sets up Pendo by invoking the `PendoFlutterPlugin.setup`
  /// method with the provided Pendo key.
  ///
  /// Returns:
  ///   - A Future<void> representing the asynchronous initialization process.

  static Future<void> init() async {
    try {
      await _plugin.setup(pendoKey);
    } catch (e) {
      dev.log('Error initializing Pendo: $e', name: 'Pendo Service - Init');
    }
  }

  /// Starts a Pendo session if not in debug mode.
  ///
  /// This function is responsible for initiating a Pendo session, which allows
  /// for user tracking and analytics. However, it only starts a session if the
  /// application is not in debug mode (kDebugMode is false). Starting a session
  /// in debug mode is typically avoided to prevent interference with development
  /// and debugging efforts.
  ///
  /// Parameters:
  ///   - code: A String containing the user's subject code acting as the visitor's ID.
  ///
  /// Returns:
  ///   - A Future<void> representing the asynchronous session start process.
  static Future<void> start(String code, String experiment) async {
    try {
      if (foundation.kDebugMode) {
        await _plugin.startSession('$experiment-$code', _testID, null, null);
      } else {
        await _plugin.startSession(
            '$experiment-$code', 'Exp-$experiment', null, null);
      }
    } catch (e) {
      dev.log('Error starting Pendo session: $e', name: 'Pendo Service - Init');
    }
  }

  /// Stops the currently active Pendo session.
  ///
  /// This function is responsible for ending the currently active Pendo session.
  /// It invokes the `PendoFlutterPlugin.endSession` method, which terminates
  /// the session and stops any ongoing tracking and analytics. Any exceptions
  /// that occur during the session termination process are caught and logged.
  ///
  /// Returns:
  ///   - A Future<void> representing the asynchronous session termination process.
  static Future<void> stop() async {
    try {
      await _plugin.endSession();
    } catch (e) {
      dev.log('Error stopping Pendo session: $e', name: 'Pendo Service - Init');
    }
  }

  /// Tracks a custom event in Pendo with optional event data.
  ///
  /// This function is used to record a custom event in Pendo, allowing for
  /// user behavior and interaction tracking. It takes an event name (`event`)
  /// and an optional map of event data (`data`). The event data can contain
  /// additional information associated with the event.
  ///
  /// Parameters:
  ///   - event: A String representing the name of the custom event to be tracked.
  ///   - data: A Map<String, dynamic>? containing optional event data.
  ///
  /// Returns:
  ///   - A Future<void> representing the asynchronous event tracking process.
  static Future<void> track(String event, Map<String, dynamic>? data) async {
    try {
      await _plugin.track(event, data);
    } catch (e) {
      dev.log('Error tracking Pendo event: $e', name: 'Pendo Service - Init');
    }
  }
}
