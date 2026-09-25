import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

String version = "1.0";

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

Future<Map<String, dynamic>> getAllDeviceInfo() async {

  final plugin = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final info = await plugin.androidInfo;

    return {
      'device_manufacturer': info.manufacturer,
      'device_model': info.model,
      'software_version': info.version.release,
      'total_storage_mb': info.totalDiskSize / (1024 * 1024),
      'available_storage_mb': info.freeDiskSize / (1024 * 1024),
      'encoding_bit_rate': 16000
    };
  }

  if (Platform.isIOS) {
    final info = await plugin.iosInfo;

    return {
      'device_manufacturer': 'Apple',
      'device_model': info.modelName,
      'software_version': info.systemVersion,
      'total_storage_mb': info.totalDiskSize / (1024 * 1024),
      'available_storage_mb': info.freeDiskSize / (1024 * 1024),
      'encoding_bit_rate': 16000
    };
  }

  return {};
}

Future<String> getAppVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}
