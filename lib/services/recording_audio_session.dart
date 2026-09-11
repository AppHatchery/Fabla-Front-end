import 'dart:async';

import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

/// The audio session behind a take: its configuration, its focus, and the
/// system events that can take either away mid-recording.
///
/// Knows nothing about the recorder. It reports what the audio system did and
/// leaves the response — pausing, publishing state, resuming — to the caller,
/// which is the only thing holding the recorder lock.
///
/// Every method reports its failures rather than throwing. These are driven
/// from stream listeners and app-lifecycle callbacks, where an escaping error
/// reaches `PlatformDispatcher.onError` and is recorded as a *fatal*.
class RecordingAudioSession {
  RecordingAudioSession({
    required this.onCaptureCompromised,
    required this.onInterruptionEnded,
  });

  /// Fires when the route or the audio focus has gone and whatever the encoder
  /// is still writing can no longer be trusted.
  final Future<void> Function() onCaptureCompromised;

  /// Fires when an interruption reports itself over. The session is not
  /// reactivated here — the caller decides whether it still wants it.
  final Future<void> Function() onInterruptionEnded;

  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;
  StreamSubscription<AudioDevicesChangedEvent>? _devicesChangedSubscription;
  StreamSubscription<void>? _becomingNoisySubscription;

  /// Ids of the input devices present when the current take started, matched
  /// against later removals to detect a route loss mid-recording.
  final Set<String> _inputDeviceIds = {};

  /// Set by [stopListening], so an event already in flight when teardown began
  /// is dropped rather than landing on a half-closed audio stack.
  bool _stopped = false;

  /// Configures the session and subscribes to the events that can end a take.
  Future<void> startListening() async {
    final session = await _configure();

    _interruptionSubscription ??= session.interruptionEventStream.listen(
      handleInterruption,
    );

    _devicesChangedSubscription ??= session.devicesChangedEventStream.listen(
      handleDevicesChanged,
    );

    // The route the recording was using disappearing — a Bluetooth headset
    // switched off, a wired mic unplugged.
    //
    // devicesChangedEventStream cannot be relied on for this. On iOS
    // audio_session derives that event by diffing the current route against
    // the previous one, and the previous one defaults to the current route
    // until a route change has already been seen. Since AudioSession.instance
    // is first created here, a headset paired before the recorder opened makes
    // its disconnect the very first route change — diffed against itself, so
    // `devicesRemoved` arrives empty and nothing pauses. This stream comes
    // straight off the `oldDeviceUnavailable` notification with no diffing, so
    // it fires the first time too.
    _becomingNoisySubscription ??= session.becomingNoisyEventStream.listen(
      (_) {
        if (_stopped) return;
        unawaited(onCaptureCompromised());
      },
    );
  }

  /// Drops the subscriptions. Call before tearing the recorder down, so no
  /// handler lands on a half-closed audio stack.
  void stopListening() {
    _stopped = true;

    unawaited(_interruptionSubscription?.cancel());
    unawaited(_devicesChangedSubscription?.cancel());
    unawaited(_becomingNoisySubscription?.cancel());

    _interruptionSubscription = null;
    _devicesChangedSubscription = null;
    _becomingNoisySubscription = null;
  }

  /// Configures and claims the session, reporting whether it took.
  ///
  /// Used both to claim it for a fresh take and to restore it after an
  /// interruption or a return to the foreground. On Android, activation is
  /// also what registers the audio-focus listener behind
  /// `interruptionEventStream` — audio_session only attaches it inside
  /// `setActive(true)` — so without this the interruption handling is
  /// iOS-only.
  Future<bool> activate() async {
    try {
      final session = await _configure();
      await session.setActive(true);
      return true;
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Audio session activation failed',
      );

      return false;
    }
  }

  /// Hands the session back once capture is done.
  ///
  /// [AndroidAudioFocusGainType.gainTransientExclusive] is a loan: the media
  /// app that paused for us only resumes when we abandon focus, which is what
  /// `setActive(false)` maps to. Without this the participant records one
  /// answer and their music stays dead for the rest of the process. iOS needs
  /// `notifyOthersOnDeactivation` for the same reason — it is what sends the
  /// other app its `shouldResume` hint — so it is passed here rather than in
  /// the configuration, where it would also apply to activation.
  ///
  /// Never called on a pause: releasing focus mid-recording would let the
  /// other app's audio back in to bleed into the mic on resume.
  Future<void> deactivate() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(
        false,
        avAudioSessionSetActiveOptions:
            AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
      );
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Audio session deactivation failed',
      );
    }
  }

  /// Snapshots the inputs available as a take starts, so a later removal can
  /// be matched against the route it actually began on.
  Future<void> captureInputDevices() async {
    try {
      final session = await AudioSession.instance;
      final devices = await session.getDevices(includeOutputs: false);

      _inputDeviceIds
        ..clear()
        ..addAll(devices.where((d) => d.isInput).map((device) => device.id));
    } catch (e, s) {
      CrashlyticsService().recordError(
        e,
        s,
        reason: 'Input device snapshot failed',
      );
    }
  }

  /// The `interruptionEventStream` subscription's target.
  ///
  /// Not private so a test can drive it without a live audio session; nothing
  /// else should call it.
  @visibleForTesting
  Future<void> handleInterruption(AudioInterruptionEvent event) async {
    if (_stopped) return;

    if (event.begin) {
      await onCaptureCompromised();
      return;
    }

    await onInterruptionEnded();
  }

  /// Reports a take losing the input it started on.
  ///
  /// Asking whether *any* input still exists would never be false: the
  /// built-in mic is always reported by [AudioSession.getDevices] and is never
  /// removed. Matching a removal against the snapshot instead is what catches
  /// the case that matters — a Bluetooth headset or wired mic dropping out and
  /// silently rerouting a live recording. The built-in mic sits harmlessly in
  /// the snapshot, since it can never be the thing that was removed.
  ///
  /// Whether a take is actually running is not checked here; that belongs to
  /// [onCaptureCompromised], which owns the recorder. The bookkeeping runs
  /// either way so the snapshot stays accurate across a pause.
  ///
  /// Not private so a test can drive it without a live audio session; nothing
  /// else should call it.
  @visibleForTesting
  Future<void> handleDevicesChanged(AudioDevicesChangedEvent event) async {
    if (_stopped) return;

    // A mic attached mid-recording takes over the route, so it becomes what a
    // later removal is matched against.
    for (final device in event.devicesAdded) {
      if (device.isInput) _inputDeviceIds.add(device.id);
    }

    var lostActiveInput = false;
    for (final device in event.devicesRemoved) {
      // Not `any`: it short-circuits, which would leave the rest of a
      // multi-device removal still marked as present.
      if (device.isInput && _inputDeviceIds.remove(device.id)) {
        lostActiveInput = true;
      }
    }

    if (!lostActiveInput) return;

    await onCaptureCompromised();
  }

  /// Applies the recording configuration and returns the shared session.
  Future<AudioSession> _configure() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      // Hard-pauses other media players rather than ducking them.
      androidAudioFocusGainType:
          AndroidAudioFocusGainType.gainTransientExclusive,
      androidWillPauseWhenDucked: true,
    ));
    return session;
  }
}
