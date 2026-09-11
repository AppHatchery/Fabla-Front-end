// AudioDevice cannot be built without naming its type, and audio_session
// marks the whole enum @experimental.
// ignore_for_file: experimental_member_use

import 'package:audio_diaries_flutter/services/recording_audio_session.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';

// Covers `RecordingAudioSession` — the audio session behind a take and the
// system events that can end one.
//
// ------------------------------------------------------------------
// What is driven here, and what is not
// ------------------------------------------------------------------
// `activate()` / `deactivate()` reach the platform, so they are out of range
// without a device — they report their own failures and return, which is all a
// test here could observe.
//
// What matters and *is* reachable is the input-device bookkeeping: which
// removals count as losing the route a take started on. That runs entirely on
// a snapshot held in Dart, so the two subscription targets are driven directly
// and the callbacks are recorded.
//
// `AudioSession.instance` does resolve in the test VM, and `getDevices()`
// answers with an empty set — which is what makes the re-snapshot test below
// meaningful rather than a stub talking to itself.
// ------------------------------------------------------------------

AudioDevice _input(String id) => AudioDevice(
      id: id,
      name: id,
      isInput: true,
      isOutput: false,
      type: AudioDeviceType.bluetoothA2dp,
    );

AudioDevice _output(String id) => AudioDevice(
      id: id,
      name: id,
      isInput: false,
      isOutput: true,
      type: AudioDeviceType.bluetoothA2dp,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int compromised;
  late int interruptionsEnded;
  late RecordingAudioSession session;

  setUp(() {
    compromised = 0;
    interruptionsEnded = 0;

    session = RecordingAudioSession(
      onCaptureCompromised: () async => compromised++,
      onInterruptionEnded: () async => interruptionsEnded++,
    );
  });

  /// Puts [ids] into the snapshot the way a mic attached mid-take would.
  Future<void> seedInputs(List<String> ids) => session.handleDevicesChanged(
        AudioDevicesChangedEvent(devicesAdded: ids.map(_input).toSet()),
      );

  group('losing an input mid-take', () {
    test('an input the take was using disappearing compromises capture',
        () async {
      await seedInputs(['headset']);
      expect(compromised, 0, reason: 'attaching a mic is not a loss');

      await session.handleDevicesChanged(
        AudioDevicesChangedEvent(devicesRemoved: {_input('headset')}),
      );

      expect(compromised, 1);
    });

    // The whole reason the snapshot exists. Asking whether *any* input is
    // still present would never be false — the built-in mic is always reported
    // and never removed — so a route this take never used dropping out must
    // not pause it.
    test('an input the take never used disappearing changes nothing', () async {
      await seedInputs(['headset']);

      await session.handleDevicesChanged(
        AudioDevicesChangedEvent(devicesRemoved: {_input('someone-elses-mic')}),
      );

      expect(compromised, 0);
    });

    test('an output disappearing changes nothing', () async {
      await seedInputs(['headset']);

      await session.handleDevicesChanged(
        AudioDevicesChangedEvent(devicesRemoved: {_output('headset')}),
      );

      expect(compromised, 0,
          reason: 'losing a speaker does not stop the mic recording');
    });

    // The removal loop must not short-circuit: a headset that leaves in the
    // same event as another device still has to come out of the snapshot, or
    // it stays there as a phantom that a later, unrelated removal can trigger
    // on.
    test('every removed input is pruned, not just the first that matched',
        () async {
      await seedInputs(['headset-a', 'headset-b']);

      await session.handleDevicesChanged(
        AudioDevicesChangedEvent(
          devicesRemoved: {_input('headset-a'), _input('headset-b')},
        ),
      );
      expect(compromised, 1, reason: 'one loss, however many devices went');

      await session.handleDevicesChanged(
        AudioDevicesChangedEvent(devicesRemoved: {_input('headset-b')}),
      );

      expect(compromised, 1,
          reason: 'headset-b was already gone; it cannot be lost twice');
    });

    test('a mic attached mid-take becomes something the take can lose',
        () async {
      await session.handleDevicesChanged(
        AudioDevicesChangedEvent(devicesRemoved: {_input('late-mic')}),
      );
      expect(compromised, 0, reason: 'not in the snapshot yet');

      await seedInputs(['late-mic']);
      await session.handleDevicesChanged(
        AudioDevicesChangedEvent(devicesRemoved: {_input('late-mic')}),
      );

      expect(compromised, 1);
    });

    // Re-snapshotting is what a resume out of an interruption does, because
    // the route may have been replaced while the take was paused. Here it
    // resolves to the empty set, so nothing carried over can still be lost.
    test('re-snapshotting the inputs drops what the previous take was on',
        () async {
      await seedInputs(['headset']);

      await session.captureInputDevices();

      await session.handleDevicesChanged(
        AudioDevicesChangedEvent(devicesRemoved: {_input('headset')}),
      );

      expect(compromised, 0);
    });
  });

  group('interruptions', () {
    test('an interruption beginning compromises capture', () async {
      await session.handleInterruption(
        AudioInterruptionEvent(true, AudioInterruptionType.pause),
      );

      expect(compromised, 1);
      expect(interruptionsEnded, 0);
    });

    // Reported rather than acted on: whether the session is worth reclaiming
    // depends on recorder state this class deliberately cannot see.
    test('an interruption ending is reported, not acted on', () async {
      await session.handleInterruption(
        AudioInterruptionEvent(false, AudioInterruptionType.pause),
      );

      expect(interruptionsEnded, 1);
      expect(compromised, 0);
    });
  });

  // Teardown cancels the subscriptions, but an event already in flight lands
  // afterwards — and pausing a recorder that dispose() has begun closing is
  // exactly the race the flag exists to stop.
  group('after stopListening()', () {
    test('an event already in flight is dropped', () async {
      await seedInputs(['headset']);

      session.stopListening();

      await session.handleDevicesChanged(
        AudioDevicesChangedEvent(devicesRemoved: {_input('headset')}),
      );
      await session.handleInterruption(
        AudioInterruptionEvent(true, AudioInterruptionType.pause),
      );
      await session.handleInterruption(
        AudioInterruptionEvent(false, AudioInterruptionType.pause),
      );

      expect(compromised, 0);
      expect(interruptionsEnded, 0);
    });
  });
}
