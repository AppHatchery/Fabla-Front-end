import 'package:audio_diaries_flutter/core/diagnostics/debug_trace.dart';
import 'dart:async';

import 'package:audio_diaries_flutter/services/developer_mode_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DeveloperModeService', () {
    late DeveloperModeService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = DeveloperModeService();
      // The service is a singleton; reset in-memory state between tests.
      await service.load();
      service.simulatedFailure.value = SimulatedFailure.none;
    });

    test('is a singleton', () {
      expect(identical(DeveloperModeService(), service), isTrue);
    });

    test('load defaults to disabled when nothing is stored', () async {
      expect(await service.load(), isFalse);
      expect(service.isEnabled, isFalse);
    });

    test('load reads the persisted value', () async {
      SharedPreferences.setMockInitialValues(
          {DeveloperModeService.preferenceKey: true});

      expect(await service.load(), isTrue);
      expect(service.enabled.value, isTrue);
    });

    test('enable persists and notifies listeners', () async {
      var notified = false;
      void listener() => notified = true;
      service.enabled.addListener(listener);
      addTearDown(() => service.enabled.removeListener(listener));

      await service.enable();

      expect(service.isEnabled, isTrue);
      expect(notified, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(DeveloperModeService.preferenceKey), isTrue);
    });

    test('disable clears the persisted value', () async {
      await service.enable();
      await service.disable();

      expect(service.isEnabled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(DeveloperModeService.preferenceKey), isFalse);
    });

    group('skip connectivity check', () {
      test('is off by default', () async {
        await service.enable();

        expect(service.skipConnectivityCheck.value, isFalse);
        expect(service.shouldSkipConnectivityCheck, isFalse);
      });

      test('persists and is reloaded', () async {
        await service.enable();
        await service.setSkipConnectivityCheck(true);

        expect(service.shouldSkipConnectivityCheck, isTrue);
        service.skipConnectivityCheck.value = false;
        await service.load();
        expect(service.shouldSkipConnectivityCheck, isTrue);
      });

      test('cannot be turned on without developer mode', () async {
        await service.setSkipConnectivityCheck(true);

        expect(service.shouldSkipConnectivityCheck, isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey(DeveloperModeService.skipConnectivityKey),
            isFalse);
      });

      test('turning developer mode off clears it', () async {
        await service.enable();
        await service.setSkipConnectivityCheck(true);

        await service.disable();

        expect(service.skipConnectivityCheck.value, isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey(DeveloperModeService.skipConnectivityKey),
            isFalse);
      });
    });

    group('simulated failures', () {
      test('throws once at the armed point, then disarms', () async {
        await service.enable();
        service.simulateNextFailure(SimulatedFailure.responseUpload);

        expect(() => service.throwIfSimulated(SimulatedFailure.responseUpload),
            throwsA(isA<SimulatedSubmissionFailure>()));
        expect(service.simulatedFailure.value, SimulatedFailure.none);
        expect(() => service.throwIfSimulated(SimulatedFailure.responseUpload),
            returnsNormally);
      });

      test('does not throw at other points', () async {
        await service.enable();
        service.simulateNextFailure(SimulatedFailure.s3Upload);

        expect(() => service.throwIfSimulated(SimulatedFailure.beforeUpload),
            returnsNormally);
        expect(service.simulatedFailure.value, SimulatedFailure.s3Upload);
      });

      test('cannot be armed without developer mode', () {
        service.simulateNextFailure(SimulatedFailure.beforeUpload);

        expect(service.simulatedFailure.value, SimulatedFailure.none);
        expect(() => service.throwIfSimulated(SimulatedFailure.beforeUpload),
            returnsNormally);
      });

      test('consumeSimulated reports and disarms without throwing', () async {
        await service.enable();
        service.simulateNextFailure(SimulatedFailure.noInternet);

        expect(service.consumeSimulated(SimulatedFailure.s3Upload), isFalse);
        expect(service.consumeSimulated(SimulatedFailure.noInternet), isTrue);
        expect(service.consumeSimulated(SimulatedFailure.noInternet), isFalse);
      });

      test('marks the current trace as simulated', () async {
        await service.enable();
        service.simulateNextFailure(SimulatedFailure.noInternet);
        final trace = DebugTrace('diary_submission');

        await trace.run(
            () async => service.consumeSimulated(SimulatedFailure.noInternet));

        expect(DeveloperModeService.isSimulated(trace), isTrue);
        expect(trace.context[DeveloperModeService.simulatedContextKey],
            'No internet');
        expect(DeveloperModeService.isSimulated(DebugTrace('other')), isFalse);
        expect(DeveloperModeService.isSimulated(null), isFalse);
      });

      test('turning developer mode off disarms it', () async {
        await service.enable();
        service.simulateNextFailure(SimulatedFailure.beforeUpload);

        await service.disable();

        expect(service.simulatedFailure.value, SimulatedFailure.none);
      });
    });

    group('reporting suppression', () {
      test('is off outside a simulated submission', () {
        expect(DeveloperModeService.shouldSuppressReporting(), isFalse);
        expect(DeveloperModeService.shouldSuppressReporting(StateError('x')),
            isFalse);
      });

      test('always applies to the simulated exception itself', () {
        expect(
            DeveloperModeService.shouldSuppressReporting(
                const SimulatedSubmissionFailure(SimulatedFailure.s3Upload)),
            isTrue);
      });

      test('applies only after the simulated failure fires', () async {
        await service.enable();
        service.simulateNextFailure(SimulatedFailure.responseUpload);

        final seen = <bool>[];
        await service.runSubmission(() async {
          seen.add(DeveloperModeService.shouldSuppressReporting());
          try {
            service.throwIfSimulated(SimulatedFailure.responseUpload);
          } catch (_) {}
          await Future<void>.delayed(Duration.zero);
          seen.add(DeveloperModeService.shouldSuppressReporting());
        });

        expect(seen, [false, true]);
        expect(DeveloperModeService.shouldSuppressReporting(), isFalse);
      });

      test('a submission whose failure point is never reached reports normally',
          () async {
        await service.enable();
        service.simulateNextFailure(SimulatedFailure.s3Upload);

        final suppressed = await service.runSubmission(() async {
          service.throwIfSimulated(SimulatedFailure.responseUpload);
          return DeveloperModeService.shouldSuppressReporting();
        });

        expect(suppressed, isFalse);
        expect(service.simulatedFailure.value, SimulatedFailure.s3Upload);
      });

      test('other work running alongside still reports', () async {
        await service.enable();
        service.simulateNextFailure(SimulatedFailure.beforeUpload);
        final otherWork = Completer<bool>();

        await Future.wait([
          service.runSubmission(() async {
            try {
              service.throwIfSimulated(SimulatedFailure.beforeUpload);
            } catch (_) {}
          }),
          Future(() async {
            await Future<void>.delayed(Duration.zero);
            otherWork.complete(DeveloperModeService.shouldSuppressReporting());
          }),
        ]);

        expect(await otherWork.future, isFalse);
      });
    });
  });
}
