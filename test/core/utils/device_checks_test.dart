import 'package:audio_diaries_flutter/core/utils/device_checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Tests for lib/core/utils/device_checks.dart.
//
// `checkLowStorage` compares the device's free bytes against a 512 MB
// threshold, and `checkLowBattery` compares the charge against 20%. Both
// halves of each are worth pinning: the storage threshold arithmetic once
// evaluated to 0 bytes so the warning could never fire, and the battery
// warning has to stay quiet whenever the device is already plugged in.
//
// Both plugins talk over method channels, so we answer those ourselves
// rather than running on a real device.

const int kMegabyte = 1024 * 1024;

const _channel = MethodChannel('dev.fluttercommunity.plus/device_info');
const _batteryChannel = MethodChannel('dev.fluttercommunity.plus/battery');

/// Answers the battery channel with a given [level] percent and [state].
void _mockBattery({required int level, required String state}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_batteryChannel, (call) async {
    switch (call.method) {
      case 'getBatteryLevel':
        return level;
      case 'getBatteryState':
        return state;
      default:
        return null;
    }
  });
}

/// Answers `getDeviceInfo` with a device that has [freeDiskSize] bytes spare.
void _mockDeviceInfo({required int freeDiskSize}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
    if (call.method != 'getDeviceInfo') return null;
    return {
      ..._commonInfo,
      'freeDiskSize': freeDiskSize,
    };
  });
}

/// Every field `AndroidDeviceInfo.fromMap` and `IosDeviceInfo.fromMap` read.
/// Only `freeDiskSize` matters here; the rest just has to be non-null so
/// parsing does not throw and get swallowed by the checker's catch.
const Map<String, dynamic> _commonInfo = {
  // Android
  'version': {'sdkInt': 34, 'release': '14', 'codename': 'REL',
    'incremental': '1', 'previewSdkInt': 0, 'securityPatch': '2024-01-01',
    'baseOS': ''},
  'board': 'board', 'bootloader': 'bootloader', 'brand': 'brand',
  'device': 'device', 'display': 'display', 'fingerprint': 'fingerprint',
  'hardware': 'hardware', 'host': 'host', 'id': 'id',
  'manufacturer': 'manufacturer', 'product': 'product', 'tags': 'tags',
  'type': 'user', 'isLowRamDevice': false, 'totalDiskSize': 64000000000,
  // iOS
  'name': 'name', 'systemName': 'iOS', 'systemVersion': '17.0',
  'localizedModel': 'iPhone', 'modelName': 'iPhone 15',
  'identifierForVendor': 'vendor-id', 'isiOSAppOnMac': false,
  'isiOSAppOnVision': false, 'utsname': {'sysname': 'Darwin',
    'nodename': 'node', 'release': '23.0', 'version': '1', 'machine': 'arm64'},
  // Shared
  'model': 'model', 'isPhysicalDevice': true,
  'physicalRamSize': 8192, 'availableRamSize': 4096,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_channel, null);
    messenger.setMockMethodCallHandler(_batteryChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('checkLowStorage threshold', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

    test('warns when free space is below 512 MB', () async {
      _mockDeviceInfo(freeDiskSize: 100 * kMegabyte);
      expect(await checkLowStorage(), isTrue);
    });

    test('warns when free space is exactly 512 MB', () async {
      _mockDeviceInfo(freeDiskSize: 512 * kMegabyte);
      expect(await checkLowStorage(), isTrue);
    });

    // Guards the original bug: the threshold rounded down to 0 bytes, so a
    // nearly full device still looked fine.
    test('warns on a device with only a few bytes left', () async {
      _mockDeviceInfo(freeDiskSize: 1);
      expect(await checkLowStorage(), isTrue);
    });

    test('stays quiet with plenty of space', () async {
      _mockDeviceInfo(freeDiskSize: 4096 * kMegabyte);
      expect(await checkLowStorage(), isFalse);
    });
  });

  group('checkLowStorage platforms', () {
    test('reads free space on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      _mockDeviceInfo(freeDiskSize: 100 * kMegabyte);
      expect(await checkLowStorage(), isTrue);
    });

    test('stays quiet on unsupported platforms', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      _mockDeviceInfo(freeDiskSize: 1);
      expect(await checkLowStorage(), isFalse);
    });

    // We would rather say nothing than nag on a guess.
    test('stays quiet when the plugin fails', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        throw PlatformException(code: 'unavailable');
      });
      expect(await checkLowStorage(), isFalse);
    });
  });

  group('checkLowBattery threshold', () {
    test('warns below 20%', () async {
      _mockBattery(level: 8, state: 'discharging');
      expect(await checkLowBattery(), isTrue);
    });

    test('warns at exactly 20%', () async {
      _mockBattery(level: 20, state: 'discharging');
      expect(await checkLowBattery(), isTrue);
    });

    test('stays quiet at 21%', () async {
      _mockBattery(level: 21, state: 'discharging');
      expect(await checkLowBattery(), isFalse);
    });

    test('stays quiet on a full charge', () async {
      _mockBattery(level: 100, state: 'discharging');
      expect(await checkLowBattery(), isFalse);
    });
  });

  group('checkLowBattery charging', () {
    // Asking someone to plug in a phone that is already plugged in is noise.
    test('stays quiet while charging, however low', () async {
      _mockBattery(level: 3, state: 'charging');
      expect(await checkLowBattery(), isFalse);
    });

    test('stays quiet while plugged in but not charging', () async {
      _mockBattery(level: 3, state: 'connected_not_charging');
      expect(await checkLowBattery(), isFalse);
    });

    test('stays quiet when the state is unknown', () async {
      _mockBattery(level: 3, state: 'unknown');
      expect(await checkLowBattery(), isFalse);
    });

    test('stays quiet when the plugin fails', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_batteryChannel, (call) async {
        throw PlatformException(code: 'unavailable');
      });
      expect(await checkLowBattery(), isFalse);
    });
  });
}
