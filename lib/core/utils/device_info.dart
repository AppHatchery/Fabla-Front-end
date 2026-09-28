library;

import 'dart:developer' as dev;


import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Warn the participant once free space drops below half a gigabyte.
const int _lowStorageThresholdBytes = 512 * 1024 * 1024;

/// Warn the participant once the charge drops to the level the OS itself
/// flags as low.
const int _lowBatteryThresholdPercent = 20;

const int _bytesPerMegabyte = 1024 * 1024;

/// The bit rate diary recordings are encoded at. `AudioRecordingService`
/// does not pass one to `startRecorder`, so this is flutter_sound's default.
/// Update both together if the recorder is ever configured explicitly.
const int diaryEncodingBitRate = 16000;


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

/// The model and OS line shown in support emails, e.g. `iPhone 15 iOS 17.0`.
Future<String> getDeviceInfo() async {
  final plugin = DeviceInfoPlugin();

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      final info = await plugin.androidInfo;
      return '${info.model} Android ${info.version.release}';
    case TargetPlatform.iOS:
      final info = await plugin.iosInfo;
      return '${info.modelName} iOS ${info.systemVersion}';
    default:
      return 'Unknown';
  }
}

Future<String> getAppVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}

/// Hardware and OS facts for the device-info table.
///
/// Holds nothing about the participant; [toRecord] adds that when the
/// snapshot is uploaded.
@immutable
class DeviceSnapshot {
  final String manufacturer;
  final String model;
  final String softwareVersion;
  final double totalStorageMb;
  final double availableStorageMb;

  const DeviceSnapshot({
    required this.manufacturer,
    required this.model,
    required this.softwareVersion,
    required this.totalStorageMb,
    required this.availableStorageMb,
  });

  /// The record the device-info Lambda stores, keyed as the backend expects.
  Map<String, dynamic> toRecord({
    required String participantId,
    required String experimentCode,
  }) =>
      {
        'ParticipantID': participantId,
        'ExperimentCode': experimentCode,
        'device_manufacturer': manufacturer,
        'device_model': model,
        'software_version': softwareVersion,
        'total_storage_mb': totalStorageMb,
        'available_storage_mb': availableStorageMb,
        'encoding_bit_rate': diaryEncodingBitRate,
      };
}

/// Reads this device's [DeviceSnapshot], or null on a platform we do not
/// upload from.
///
/// Throws if the plugin fails; the caller decides how to report it.
/// [preferenceService] can be injected for testing.
Future<DeviceSnapshot?> collectDeviceSnapshot({
  PreferenceService? preferenceService,
}) async {
  final plugin = DeviceInfoPlugin();

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      final info = await plugin.androidInfo;
      return DeviceSnapshot(
        manufacturer: info.manufacturer,
        model: info.model,
        softwareVersion: info.version.release,
        totalStorageMb: info.totalDiskSize / _bytesPerMegabyte,
        availableStorageMb: info.freeDiskSize / _bytesPerMegabyte,
      );
    case TargetPlatform.iOS:
      final info = await plugin.iosInfo;
      return DeviceSnapshot(
        // Null until the device is first unlocked after a restart.
        manufacturer: 'Apple',
        model: info.modelName,
        softwareVersion: info.systemVersion,
        totalStorageMb: info.totalDiskSize / _bytesPerMegabyte,
        availableStorageMb: info.freeDiskSize / _bytesPerMegabyte,
      );
    default:
      return null;
  }
}

