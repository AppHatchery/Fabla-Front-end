import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  late SharedPreferences _preferences;

  Future<void> _initializePreferences() async =>
      _preferences = await SharedPreferences.getInstance();

  Future<String?> getStringPreference({required String key}) async {
    await _initializePreferences();
    return _preferences.getString(key);
  }

  Future<bool> setStringPreference(
      {required String key, required String value}) async {
    await _initializePreferences();
    return _preferences.setString(key, value);
  }

  Future<bool?> getBoolPreference({required String key}) async {
    await _initializePreferences();
    return _preferences.getBool(key);
  }

  Future<bool> setBoolPreference(
      {required String key, required bool value}) async {
    await _initializePreferences();
    return _preferences.setBool(key, value);
  }

  Future<int?> getIntPreference({required String key}) async {
    await _initializePreferences();
    return _preferences.getInt(key);
  }

  Future<bool> setIntPreference(
      {required String key, required int value}) async {
    await _initializePreferences();
    return _preferences.setInt(key, value);
  }

  Future<double?> getDoublePreference({required String key}) async {
    await _initializePreferences();
    return _preferences.getDouble(key);
  }

  Future<bool> setDoublePreference(
      {required String key, required double value}) async {
    await _initializePreferences();
    return _preferences.setDouble(key, value);
  }

  Future<List<String>?> getStringListPreference({required String key}) async {
    await _initializePreferences();
    return _preferences.getStringList(key);
  }

  Future<bool> setStringListPreference(
      {required String key, required List<String> value}) async {
    await _initializePreferences();
    return _preferences.setStringList(key, value);
  }

  Future<bool> removePreference({required String key}) async {
    await _initializePreferences();
    return _preferences.remove(key);
  }

  Future<bool> clearPreferences() async {
    await _initializePreferences();
    return _preferences.clear();
  }
}
