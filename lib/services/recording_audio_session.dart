import 'dart:async';

import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

/// The audio session behind a take: its configuration, its focus, and the
/// system events that can take either away mid-recording.
///
/// Knows nothing about the recorder. It reports what the audio system did and
/// leaves the response — pausing, resuming, publishing state — to the caller,
/// which is the only thing holding the recorder lock.
///
/// Every method reports failures instead of throwing, because these run from
/// stream listeners where an escaping error is logged as a *fatal*.
class RecordingAudioSession {
  RecordingAudioSession({
    required this.onCaptureCompromised,
  });

  final Future<void> Function() onCaptureCompromised;

  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;
  StreamSubscription<AudioDevicesChangedEvent>? _devicesChangedSubscription;
  StreamSubscription<void>? _becomingNoisySubscription;

  final Set<String> _inputDeviceIds = {};

  bool _stopped = false;

  Future<void> startListening() async {
    final session = await _configure();

    _interruptionSubscription ??= session.interruptionEventStream.listen(
      handleInterruption,
    );

    _devicesChangedSubscription ??= session.devicesChangedEventStream.listen(
      handleDevicesChanged,
    );

    _becomingNoisySubscription ??= session.becomingNoisyEventStream.listen(
      (_) {
        if (_stopped) return;
        unawaited(onCaptureCompromised());
      },
    );
  }

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
  /// Used to claim the session for a new take and to restore it after an
  /// interruption. On Android this is also what registers the audio-focus
  /// listener behind `interruptionEventStream`, so without it the interruption
  /// handling would be iOS-only.
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
  /// Audio focus is borrowed, not taken: the media app that paused for us only
  /// resumes when we give it back, which is what `setActive(false)` does.
  /// Without this the participant records one answer and their music stays dead.
  /// iOS needs `notifyOthersOnDeactivation` to send the same hint.
  ///
  /// Never called on a pause: giving focus back mid-recording would let the
  /// other app's audio bleed into the mic on resume.
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
    _inputDeviceIds.clear();

    try {
      final session = await AudioSession.instance;
      final devices = await session.getDevices(includeOutputs: false);

      _inputDeviceIds
          .addAll(devices.where((d) => d.isInput).map((device) => device.id));
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
  /// Only the beginning of an interruption is reported. The end of one needs
  /// no response: the take is still paused, and Siri finishing is not the
  /// participant deciding to go back to their answer — that is the resume,
  /// which reclaims the session itself, at the point it is needed. Reclaiming
  /// it here instead reconfigured the session under a paused recorder for
  /// nothing, and took down the notice telling the participant the take was
  /// waiting for them.
  ///
  /// Not private so a test can drive it without a live audio session; nothing
  /// else should call it.
  @visibleForTesting
  Future<void> handleInterruption(AudioInterruptionEvent event) async {
    if (_stopped) return;

    if (event.begin) await onCaptureCompromised();
  }

  /// Reports a take losing the input it started on.
  ///
  /// Asking "is any input left" would never be false, because the built-in mic
  /// is always listed and never removed. Matching a removal against the
  /// snapshot instead catches the case that matters: a headset or wired mic
  /// dropping out and silently rerouting a live recording.
  ///
  /// Whether a take is running is not checked here — that belongs to
  /// [onCaptureCompromised], which owns the recorder. The bookkeeping runs
  /// either way, so the snapshot stays right across a pause.
  ///
  /// Not private so a test can drive it without a live audio session.
  @visibleForTesting
  Future<void> handleDevicesChanged(AudioDevicesChangedEvent event) async {
    if (_stopped) return;

    for (final device in event.devicesAdded) {
      if (device.isInput) _inputDeviceIds.add(device.id);
    }

    var lostActiveInput = false;
    for (final device in event.devicesRemoved) {
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
