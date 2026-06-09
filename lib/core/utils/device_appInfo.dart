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

Future<String> getAppVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}
