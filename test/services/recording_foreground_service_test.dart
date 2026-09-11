import 'dart:io';

import 'package:audio_diaries_flutter/services/recording_foreground_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Covers `RecordingForegroundService` — the microphone foreground service that
// keeps a take capturing while the app is off screen.
//
// ------------------------------------------------------------------
// What a host without Android can prove
// ------------------------------------------------------------------
// Starting the service is Android-only and needs a real one: the plugin talks
// to a platform channel, and the branches worth having — adopting a service a
// previous take left running, a ServiceRequestFailure from a device that
// refuses — are only reachable there.
//
// What is reachable here is the contract the recorder reads. `isActive` is not
// a record of what was attempted; it is the answer to "can this take survive a
// background switch", and `AudioRecordingService.handleAppBackgrounded()`
// pauses the take whenever it is false. So the tests below pin that a service
// which is not up never claims to be.
// ------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('is inactive until something starts it', () {
    expect(RecordingForegroundService().isActive, isFalse);
  });

  test('reports the take as foreground-only where there is no service to run',
      () async {
    // Guarding the whole test rather than asserting on the platform: on an
    // Android host this would reach the plugin, and the answer would be about
    // the device rather than about this class.
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
