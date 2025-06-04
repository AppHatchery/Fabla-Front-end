import 'package:audio_diaries_flutter/core/secrets/keys.dart'; // Import for pendoKey
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode, no prefix needed for direct use/assignment in test
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendo_sdk/pendo_sdk.dart'; // Import for PendoFlutterPlugin if needed for types

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Define the method channel name used by PendoFlutterPlugin
  // Updated assumption for the channel name.
  const MethodChannel channel = MethodChannel('pendo_flutter_plugin');

  // Store method calls for verification
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'setup':
        case 'startSession':
        case 'endSession':
        case 'track':
          return null;
        default:
          return null;
      }
    });
    log.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('PendoService Tests', () {
    test('init should call PendoFlutterPlugin.setup with correct key',
        () async {
      await PendoService.init();
      expect(log, <Matcher>[
        isMethodCall('setup', arguments: {'pendoKey': pendoKey})
      ]);
    });

    group('start method', () {
      // Test kDebugMode = true path (default in tests)
      // The PendoService reads kDebugMode directly, which is true in test environments.
      test('should call startSession with visitorId and _testID in debug mode',
          () async {
        // Verify that kDebugMode is indeed true in the test environment as expected.
        // This assertion helps confirm the test premise.
        expect(kDebugMode, isTrue,
            reason: "Tests should run with kDebugMode = true by default.");

        const testVisitorId = 'debugUser';
        const testAccountId =
            'debugExp'; // This will be used to form 'Exp-debugExp' if kDebugMode was false
        await PendoService.start(testVisitorId, testAccountId);

        expect(log, <Matcher>[
          isMethodCall('startSession', arguments: {
            'visitorId': testVisitorId,
            'accountId': 'Test', // Expecting 'Test' because kDebugMode is true
            'visitorData': null,
            'accountData': null,
          })
        ]);
      });

      // Note: Testing the kDebugMode == false path for PendoService.start()
      // would require refactoring PendoService to make the debug status check injectable
      // or allow overriding it for tests, as kDebugMode is a compile-time constant.
    });

    test('stop should call endSession', () async {
      await PendoService.stop();
      expect(log, <Matcher>[isMethodCall('endSession', arguments: null)]);
    });

    test('track should call PendoFlutterPlugin.track with event and data',
        () async {
      const eventName = 'testEvent';
      final eventData = {'key': 'value'};
      await PendoService.track(eventName, eventData);

      expect(log, <Matcher>[
        isMethodCall('track', arguments: {
          'eventName': eventName,
          'properties': eventData,
        })
      ]);
    });

    test('track should call PendoFlutterPlugin.track with event and null data',
        () async {
      const eventName = 'testEventNoData';
      await PendoService.track(eventName, null);

      expect(log, <Matcher>[
        isMethodCall('track', arguments: {
          'eventName': eventName,
          'properties': null,
        })
      ]);
    });

    test('init should handle errors from plugin setup (does not rethrow)',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'setup') {
          throw PlatformException(code: 'ERROR', message: 'Pendo setup failed');
        }
        return null;
      });
      await PendoService
          .init(); // PendoService catches and logs, does not rethrow.
      // We primarily ensure the test doesn't crash due to an unhandled exception by PendoService.
      expect(log.isEmpty, isTrue,
          reason:
              "Setup method call should have failed and not been logged normally.");
      // Further assertion could involve checking log output if a log interceptor was used.
    });
  });
}
