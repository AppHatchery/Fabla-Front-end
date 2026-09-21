
library;

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:developer' as dev;
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';


String version = "1.0";

/// Warn the participant once free space drops below half a gigabyte.
const int _lowStorageThresholdBytes = 512 * 1024 * 1024;

/// Warn the participant once the charge drops to the level the OS itself
/// flags as low.
const int _lowBatteryThresholdPercent = 20;

/// Whether the device is too low on space to safely store new recordings.
Future<bool> checkLowStorage() async {
  final deviceInfo = DeviceInfoPlugin();

  try {
    final int freeDiskBytes;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        freeDiskBytes = (await deviceInfo.androidInfo).freeDiskSize;
      case TargetPlatform.iOS:
        freeDiskBytes = (await deviceInfo.iosInfo).freeDiskSize;
      default:
        return false;
    }

    return freeDiskBytes <= _lowStorageThresholdBytes;
  } catch (e) {
    dev.log('Failed to check free storage: $e');
    return false;
  }
}

/// Whether the battery is low enough to risk cutting a recording short.
///
/// Stays quiet whenever the device is plugged in, since the participant has
/// already done the thing the warning would ask of them.
Future<bool> checkLowBattery() async {
  final battery = Battery();

  try {
    final state = await battery.batteryState;
    if (state != BatteryState.discharging) return false;

    return await battery.batteryLevel <= _lowBatteryThresholdPercent;
  } catch (e) {
    dev.log('Failed to check battery level: $e');
    return false;
  }
}


Future<String> getDeviceInfo() async {
  final plugin = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final info = await plugin.androidInfo;
    return '${info.model} Android ${info.version.release}';
  } else if (Platform.isIOS) {
    final info = await plugin.iosInfo;
    return '${info.modelName} iOS ${info.systemVersion}';
  }

  return 'Unknown';
}

Future<String> getAppVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}
