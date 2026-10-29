import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoCollector {
  DeviceInfoCollector._();

  static Future<Map<String, dynamic>> collect(BuildContext context) async {
    final info = <String, dynamic>{};

    final package = await PackageInfo.fromPlatform();
    info['appVersion'] = package.version;
    info['buildNumber'] = package.buildNumber;
    info['packageName'] = package.packageName;

    try {
      final android = await DeviceInfoPlugin().androidInfo;
      info['platform'] = 'android';
      info['manufacturer'] = android.manufacturer;
      info['model'] = android.model;
      info['device'] = android.device;
      info['androidVersion'] = android.version.release;
      info['sdkInt'] = android.version.sdkInt;
      info['physicalDevice'] = android.isPhysicalDevice;
    } catch (_) {
      info['platform'] = 'unknown';
    }

    if (context.mounted) {
      final media = MediaQuery.of(context);
      info['screenWidth'] = media.size.width;
      info['screenHeight'] = media.size.height;
      info['devicePixelRatio'] = media.devicePixelRatio;
    }
    info['locale'] =
        WidgetsBinding.instance.platformDispatcher.locale.toString();

    return info;
  }
}
