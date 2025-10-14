import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

Future<bool> checkForInternet() async {
  try {
    // if in debug mode, always return true
    if (kDebugMode) return true;
    bool result = await InternetConnection().hasInternetAccess;
    return result;
  } catch (e, stackTrace) {
    CrashlyticsService().recordError(e, stackTrace,
        reason: 'Error checking internet connectivity in checkForInternet');
    return false;
  }
}
