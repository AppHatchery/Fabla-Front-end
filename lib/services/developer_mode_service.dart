import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/diagnostics/debug_trace.dart';
import '../core/utils/app_clock.dart';
import 'preference_service.dart';

/// Points in the submission flow where developer mode can force a failure.
enum SimulatedFailure {
  none('Off', 'Submissions run normally'),
  noInternet(
      'No internet', 'Acts as if offline: the diary is saved to submit later'),
  beforeUpload('Before upload', 'Throws after the upload is prepared'),
  presignedUrl('Presigned URL',
      'Fails getting a file upload URL (diaries with recordings)'),
  s3Upload('File upload',
      'Fails uploading a recording to storage (diaries with recordings)'),
  responseUpload('Response upload', 'Fails sending the responses');

  final String label;
  final String description;
  const SimulatedFailure(this.label, this.description);
}

/// Thrown by [DeveloperModeService.throwIfSimulated] to fake a failure.
class SimulatedSubmissionFailure implements Exception {
  final SimulatedFailure point;
  const SimulatedSubmissionFailure(this.point);

  @override
  String toString() =>
      'SimulatedSubmissionFailure: forced failure at "${point.label}" '
      '(developer mode)';
}

/// Tracks whether a simulated failure fired within one submission.
class _SimulationScope {
  bool fired = false;
}

/// Manages the hidden developer mode used by testers to surface debug
/// information (e.g. detailed submission errors) in release builds.
///
/// Developer mode is enabled by tapping "Powered by AppHatchery" in Settings
/// [requiredTaps] times, and persists across restarts in shared preferences.
/// It is cleared when the participant leaves the study.
///
/// Usage example:
/// ```dart
/// await DeveloperModeService().load();
/// ValueListenableBuilder<bool>(
///   valueListenable: DeveloperModeService().enabled,
///   builder: (context, isEnabled, _) => ...,
/// );
/// ```
class DeveloperModeService {
  static final DeveloperModeService _instance =
      DeveloperModeService._internal();
  factory DeveloperModeService() => _instance;
  DeveloperModeService._internal();

  static const String preferenceKey = 'developer_mode_enabled';
  static const String skipConnectivityKey = 'developer_skip_connectivity_check';
  static const String timeTravelKey = 'developer_time_travel_minutes';

  static final Object _simulationScopeKey = Object();

  /// Number of consecutive taps needed to enable developer mode.
  static const int requiredTaps = 10;

  final PreferenceService _preferences = PreferenceService();

  /// Whether developer mode is currently enabled. Listen to this to show or
  /// hide developer-only UI.
  final ValueNotifier<bool> enabled = ValueNotifier(false);

  bool get isEnabled => enabled.value;

  /// Whether internet checks are bypassed so submissions go straight to the
  /// network, and the homepage never shows the offline card. Persisted, and
  /// cleared with developer mode.
  final ValueNotifier<bool> skipConnectivityCheck = ValueNotifier(false);

  /// Whether the connectivity check should be skipped right now: the option
  /// is on and developer mode is enabled.
  bool get shouldSkipConnectivityCheck =>
      isEnabled && skipConnectivityCheck.value;

  Future<void> setSkipConnectivityCheck(bool value) async {
    if (!isEnabled) return;
    if (value) {
      await _preferences.setBoolPreference(
          key: skipConnectivityKey, value: true);
    } else {
      await _preferences.removePreference(key: skipConnectivityKey);
    }
    skipConnectivityCheck.value = value;
  }

  /// How far the app's clock ([AppClock]) is shifted from the device clock.
  /// Persisted, and cleared with developer mode. Set it through `TimeTravel`,
  /// which also snapshots diary statuses so they can be repaired afterwards.
  final ValueNotifier<Duration> timeTravel = ValueNotifier(Duration.zero);

  bool get isTimeTravelling => timeTravel.value != Duration.zero;

  Future<void> setTimeTravel(Duration offset) async {
    if (!isEnabled) return;
    if (offset == Duration.zero) {
      await _preferences.removePreference(key: timeTravelKey);
    } else {
      await _preferences.setIntPreference(
          key: timeTravelKey, value: offset.inMinutes);
    }
    _applyTimeTravel(offset);
  }

  void _applyTimeTravel(Duration offset) {
    AppClock.offset = offset;
    timeTravel.value = offset;
  }

  /// Where the next submission is forced to fail. In memory only, so it never
  /// survives a restart, and cleared after it fires once.
  final ValueNotifier<SimulatedFailure> simulatedFailure =
      ValueNotifier(SimulatedFailure.none);

  /// Arms a one-shot failure at [point] for the next submission.
  void simulateNextFailure(SimulatedFailure point) {
    if (!isEnabled) return;
    simulatedFailure.value = point;
  }

  /// Throws [SimulatedSubmissionFailure] if a failure is armed at [point],
  /// then disarms it. A no-op unless developer mode is on.
  void throwIfSimulated(SimulatedFailure point) {
    if (consumeSimulated(point)) throw SimulatedSubmissionFailure(point);
  }

  /// Whether a failure is armed at [point], disarming it if so. For failures
  /// that are a result rather than an exception, like no internet. Marks the
  /// current [DebugTrace] as simulated (see [isSimulated]). A no-op unless
  /// developer mode is on.
  bool consumeSimulated(SimulatedFailure point) {
    if (!isEnabled || simulatedFailure.value != point) return false;
    simulatedFailure.value = SimulatedFailure.none;
    (Zone.current[_simulationScopeKey] as _SimulationScope?)?.fired = true;
    DebugTrace.current?.context[simulatedContextKey] = point.label;
    return true;
  }

  /// [DebugTrace.context] entry naming the simulated failure, if one fired.
  static const String simulatedContextKey = 'Simulated failure';

  /// Whether [trace] ended in a simulated failure, so its reporting can be
  /// skipped outside the submission's zone (e.g. Pendo events in the UI).
  static bool isSimulated(DebugTrace? trace) =>
      trace?.context.containsKey(simulatedContextKey) ?? false;

  /// Runs one submission. If a failure is armed, [body] runs in a scope so
  /// that, once the simulated failure fires, the rest of the submission's
  /// error reporting is suppressed (see [shouldSuppressReporting]).
  Future<T> runSubmission<T>(Future<T> Function() body) {
    if (simulatedFailure.value == SimulatedFailure.none) return body();
    return runZoned(body,
        zoneValues: {_simulationScopeKey: _SimulationScope()});
  }

  /// Whether error reporting (Crashlytics, Pendo) should be skipped because
  /// it comes from a simulated failure rather than a real one.
  static bool shouldSuppressReporting([Object? error]) =>
      error is SimulatedSubmissionFailure ||
      ((Zone.current[_simulationScopeKey] as _SimulationScope?)?.fired ??
          false);

  /// Loads the persisted developer mode state into [enabled].
  Future<bool> load() async {
    enabled.value =
        await _preferences.getBoolPreference(key: preferenceKey) ?? false;
    skipConnectivityCheck.value = enabled.value &&
        (await _preferences.getBoolPreference(key: skipConnectivityKey) ??
            false);
    final minutes = enabled.value
        ? await _preferences.getIntPreference(key: timeTravelKey)
        : null;
    _applyTimeTravel(Duration(minutes: minutes ?? 0));
    return enabled.value;
  }

  Future<void> enable() async {
    await _preferences.setBoolPreference(key: preferenceKey, value: true);
    enabled.value = true;
  }

  Future<void> disable() async {
    await _preferences.removePreference(key: preferenceKey);
    await _preferences.removePreference(key: skipConnectivityKey);
    await _preferences.removePreference(key: timeTravelKey);
    enabled.value = false;
    simulatedFailure.value = SimulatedFailure.none;
    skipConnectivityCheck.value = false;
    _applyTimeTravel(Duration.zero);
  }
}
