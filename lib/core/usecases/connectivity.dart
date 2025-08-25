import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

Future<bool> checkForInternet() async {
  try {
    bool result = await InternetConnection().hasInternetAccess;
    return result;
  } catch (e) {
    return false;
  }
}
