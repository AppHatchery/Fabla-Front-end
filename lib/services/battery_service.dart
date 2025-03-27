import 'package:flutter/services.dart';
import 'dart:developer' as dev;

class BatteryService {
  static const channel =
      MethodChannel('edu.emory.audio_diaries_flutter/battery');
  static const requestEvent = EventChannel('edu.emory.audio_diaries_flutter/batteryRequest');

  /// Method to check if the battery optimization is disabled.
  ///
  /// Returns:
  /// The method returns a boolean value indicating if the battery optimization is disabled.
  ///
  Future<bool> isBatteryOptimizationDisabled() async {
    try {
      final bool isDisabled =
          await channel.invokeMethod('isBatteryOptimizationDisabled');
      return isDisabled;
    } on PlatformException catch (e) {
      dev.log(e.message.toString(),
          name: "Battery Service - isBatteryOptimizationDisabled");
      throw Exception(e.message);
    }
  }

  // Future<bool> requestIgnoreBatteryOptimization() async {
  //   try {
  //     // set up the method call handler to listen for the result
  //     bool? result;
  //     channel.setMethodCallHandler((call) async {
  //       if (call.method == 'onBatteryOptimizationResult') {
  //         result = call.arguments as bool;
  //         return true;
  //       }
  //       return null;
  //     });

  //     // Then invoke the method to open settings
  //     await channel.invokeMethod('requestIgnoreBatteryOptimization');

  //     // Wait for the result from the onActivityResult callback
  //     int attempts = 0;
  //     while (result == null && attempts < 30) {
  //       await Future.delayed(Duration(milliseconds: 500));
  //       attempts++;
  //     }

  //     final bool isDisabled = result ?? false;
  //     return isDisabled;
  //   } on PlatformException catch (e) {
  //     dev.log(e.message.toString(),
  //         name: "Battery Service - requestIgnoreBatteryOptimization");
  //     throw Exception(e.message);
  //   }
  // }
}
