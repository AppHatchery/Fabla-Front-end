import 'package:audio_diaries_flutter/core/secrets/keys.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:pendo_sdk/pendo_sdk.dart';

const String _testID = "Test";

class PendoService {
  /// Initializes the Pendo Flutter plugin with the given Pendo key.
  ///
  /// This function sets up Pendo by invoking the `PendoFlutterPlugin.setup`
  /// method with the provided Pendo key.
  ///
  /// Returns:
  ///   - A Future<void> representing the asynchronous initialization process.

  static Future<void> init() async {
    try {
      await PendoFlutterPlugin.setup(pendoKey);
    } catch (e) {
      print('Error initializing Pendo: $e');
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
        await PendoFlutterPlugin.startSession(code, _testID, null, null);
      } else {
        await PendoFlutterPlugin.startSession(code, 'Exp-$experiment', null, null);
      }
    } catch (e) {
      print('Error starting Pendo session: $e');
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
      await PendoFlutterPlugin.endSession();
    } catch (e) {
      print('Error stopping Pendo session: $e');
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
      await PendoFlutterPlugin.track(event, data);
    } catch (e) {
      print('Error tracking Pendo event: $e');
    }
  }
}
