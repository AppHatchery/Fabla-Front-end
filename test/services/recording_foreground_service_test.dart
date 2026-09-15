import 'dart:io';

import 'package:audio_diaries_flutter/services/recording_foreground_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Covers `RecordingForegroundService` — the microphone foreground service that
// keeps a take capturing while the app is off screen.
//
// ------------------------------------------------------------------
// What a host without Android can prove
// ------------------------------------------------------------------
// Starting the service needs a real Android device, so those branches are out
// of range here.
//
// What is reachable is the contract the recorder reads. `isActive` answers
// "can this take survive a background switch", and handleAppBackgrounded()
// pauses whenever it is false — so these tests pin that a service which is not
// up never claims to be.
// ------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('is inactive until something starts it', () {
    expect(RecordingForegroundService().isActive, isFalse);
  });

  test('reports the take as foreground-only where there is no service to run',
      () async {
    // Skipped rather than asserted on Android, where this would reach the
    // plugin and the answer would be about the device, not this class.
    if (Platform.isAndroid) return;

    final service = RecordingForegroundService();

    expect(await service.start(), isFalse);
    expect(service.isActive, isFalse,
        reason: 'a start that did nothing must not claim the take is covered');
  });

  test('stopping a service that never started is a no-op', () async {
    final service = RecordingForegroundService();

    // Reaching the plugin here would throw MissingPluginException, so this
    // returning quietly is also what proves the early exit is taken.
    await service.stop();

    expect(service.isActive, isFalse);
  });
}
