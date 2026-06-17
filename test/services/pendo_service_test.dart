// PendoService will now bring IPendoPlugin, PendoPluginWrapper
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:flutter/services.dart'; // For MethodCall and PlatformException
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

// PendoFlutterPlugin import is no longer needed for direct mocking here
// import 'package:pendo_sdk/pendo_sdk.dart';

// Mock implementation for IPendoPlugin
class MockPendoPlugin implements IPendoPlugin {
  final List<MethodCall> log;
  Object? errorToThrow; // To simulate errors for specific tests

  MockPendoPlugin(this.log);

  @override
  Future<void> setup(String pendoKey) async {
    if (errorToThrow != null &&
        errorToThrow is PlatformException &&
        (errorToThrow as PlatformException).message!.contains('setup')) {
      throw errorToThrow!;
    }
    log.add(MethodCall('setup', {'pendoKey': pendoKey}));
    return Future.value();
  }

  @override
  Future<void> startSession(
      String visitorId,
      String accountId,
      Map<String, dynamic>? visitorData,
      Map<String, dynamic>? accountData) async {
    log.add(MethodCall('startSession', {
      'visitorId': visitorId,
      'accountId': accountId,
      'visitorData': visitorData,
      'accountData': accountData,
    }));
    return Future.value();
  }

  @override
  Future<void> endSession() async {
    log.add(const MethodCall('endSession'));
    return Future.value();
  }

  @override
  Future<void> track(String eventName, Map<String, dynamic>? properties) async {
    log.add(MethodCall('track', {
      'eventName': eventName,
      'properties': properties,
    }));
    return Future.value();
  }

  void simulateSetupError(PlatformException exception) {
    errorToThrow = exception;
  }

  void clearError() {
    errorToThrow = null;
  }
}

void main() {
  setUpAll(() {
    // PendoService.init() reads `dotenv.env['PENDOKEY']!`. Seed dotenv before
    // any test runs so the null-assertion doesn't blow up inside init()'s
    // try/catch (which would swallow the error and leave the mock log empty).
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.loadFromString(
      envString: 'PENDOKEY=test-pendo-key',
    );
  });

  // Store method calls for verification
  late List<MethodCall> log;
  late MockPendoPlugin mockPendoPlugin;

  setUp(() {
    log = <MethodCall>[];
    mockPendoPlugin = MockPendoPlugin(log);
    PendoService.setPluginForTesting(mockPendoPlugin);
  });

  tearDown(() {
    // Reset the plugin to its default implementation after each test
    PendoService.resetPlugin();
    mockPendoPlugin.clearError(); // Clear any simulated errors
  });

  group('PendoService Tests', () {
    test('init should call PendoFlutterPlugin.setup with correct key',
        () async {
      await PendoService.init();
      expect(log, <Matcher>[
        isMethodCall('setup', arguments: {'pendoKey': dotenv.env['PENDOKEY']})
      ]);
    });

    group('start method', () {
      test('should call startSession with visitorId and _testID in debug mode',
          () async {
        expect(kDebugMode, isTrue,
            reason: "Tests should run with kDebugMode = true by default.");

        const testVisitorId = 'debugUser';
        const testAccountId = 'debugExp';
        await PendoService.start(testVisitorId, testAccountId);

        expect(log, <Matcher>[
          isMethodCall('startSession', arguments: {
            'visitorId': '$testAccountId-$testVisitorId',
            'accountId': 'Test', // Expecting 'Test' because kDebugMode is true
            'visitorData': null,
            'accountData': null,
          })
        ]);
      });

      // Note: Testing the kDebugMode == false path for PendoService.start()
      // would require refactoring PendoService to make the debug status check injectable
      // or allow overriding it for tests, as kDebugMode is a compile-time constant.
      // This remains true, but the PendoService logic itself can be tested.
    });

    test('stop should call endSession', () async {
      await PendoService.stop();
      // The arguments for endSession in the original MethodChannel mock were null.
      // If MockPendoPlugin.endSession adds MethodCall('endSession', arguments: null), this is fine.
      // If it adds MethodCall('endSession') which implies null arguments for isMethodCall, that's also fine.
      // Let's ensure MockPendoPlugin.endSession adds `const MethodCall('endSession')`
      // and isMethodCall handles arguments: null correctly.
      // The `isMethodCall` matcher with `arguments: null` works correctly when no arguments are passed to MethodCall.
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
      final platformException =
          PlatformException(code: 'ERROR', message: 'Pendo setup failed');
      mockPendoPlugin.simulateSetupError(platformException);

      // Clear the log before the call, as setup might add to it before throwing
      // if the error simulation logic in mock isn't perfect.
      // However, a well-behaved mock should throw before logging.
      // Our mockPendoPlugin.setup is designed to throw before logging if errorToThrow is set for 'setup'.
      // log.clear(); // Not strictly necessary if mock behaves as intended.

      await PendoService
          .init(); // PendoService catches and logs, does not rethrow.

      // Expect that the setup method in the mock was attempted and threw.
      // The log should be empty because if an error is thrown in mockPendoPlugin.setup,
      // it won't add the MethodCall to the log.
      expect(log.isEmpty, isTrue,
          reason:
              "Setup method call in mock should have thrown and not been logged.");

      // To be more robust, we could also check that PendoService logged the error,
      // but that would require a log-capturing mechanism for dev.log, which is outside
      // the scope of this specific plugin interaction test.
    });
  });
}
