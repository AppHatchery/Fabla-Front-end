import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audio_diaries_flutter/services/battery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BatteryService Tests', () {
    late BatteryService batteryService;
    late MethodChannel channel;

    setUp(() {
      batteryService = BatteryService();
      channel = const MethodChannel('edu.emory.audio_diaries_flutter/battery');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
        'isBatteryOptimizationDisabled returns true when optimization is disabled',
        () async {
      // Mock the platform channel to return true
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isBatteryOptimizationDisabled') {
          return true;
        }
        return null;
      });

      final result = await batteryService.isBatteryOptimizationDisabled();
      expect(result, isTrue);
    });

    test(
        'isBatteryOptimizationDisabled returns false when optimization is enabled',
        () async {
      // Mock the platform channel to return false
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isBatteryOptimizationDisabled') {
          return false;
        }
        return null;
      });

      final result = await batteryService.isBatteryOptimizationDisabled();
      expect(result, isFalse);
    });

    test('isBatteryOptimizationDisabled throws exception on platform error',
        () async {
      // Mock the platform channel to throw an exception
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isBatteryOptimizationDisabled') {
          throw PlatformException(
            code: 'ERROR_CODE',
            message: 'Test error message',
          );
        }
        return null;
      });

      expect(
        () => batteryService.isBatteryOptimizationDisabled(),
        throwsException,
      );
    });

    // test('isBatteryOptimizationDisabled handles null response from platform',
    //     () async {
    //   // Mock the platform channel to return null
    //   TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    //       .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    //     if (methodCall.method == 'isBatteryOptimizationDisabled') {
    //       return null;
    //     }
    //     return null;
    //   });

    //   final result = await batteryService.isBatteryOptimizationDisabled();
    //   expect(result, isFalse);
    // });
  });

  //This comment is here to trigger a pre-commit hook test
}
