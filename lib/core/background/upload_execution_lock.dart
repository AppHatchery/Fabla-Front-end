import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Prevents the foreground isolate and a Workmanager isolate from submitting
/// the same pending diary at the same time.
class UploadExecutionLock {
  static const _storageKey = 'background_upload_execution_lock_v1';
  static const _lockLifetime = Duration(minutes: 15);

  final SharedPreferencesAsync _preferences;
  final DateTime Function() _now;
  final Random _random;

  UploadExecutionLock({
    SharedPreferencesAsync? preferences,
    DateTime Function()? now,
    Random? random,
  })  : _preferences = preferences ?? SharedPreferencesAsync(),
        _now = now ?? DateTime.now,
        _random = random ?? Random.secure();

  /// Returns an ownership token, or `null` when another upload is active.
  Future<String?> acquire() async {
    final now = _now();
    final stored = await _preferences.getString(_storageKey);
    if (_isActive(stored, now)) return null;

    final token = '${now.microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
    await _preferences.setString(
      _storageKey,
      jsonEncode({
        'token': token,
        'expiresAt': now.add(_lockLifetime).millisecondsSinceEpoch,
      }),
    );

    // Re-read from disk so two isolates racing to acquire the lock agree on
    // the last writer as the owner.
    final confirmed = await _preferences.getString(_storageKey);
    return _tokenFrom(confirmed) == token ? token : null;
  }

  Future<void> release(String token) async {
    final stored = await _preferences.getString(_storageKey);
    if (_tokenFrom(stored) == token) {
      await _preferences.remove(_storageKey);
    }
  }

  bool _isActive(String? value, DateTime now) {
    if (value == null) return false;
    try {
      final data = jsonDecode(value) as Map<String, dynamic>;
      final expiresAt = data['expiresAt'] as int?;
      return expiresAt != null &&
          DateTime.fromMillisecondsSinceEpoch(expiresAt).isAfter(now);
    } catch (_) {
      return false;
    }
  }

  String? _tokenFrom(String? value) {
    if (value == null) return null;
    try {
      return (jsonDecode(value) as Map<String, dynamic>)['token'] as String?;
    } catch (_) {
      return null;
    }
  }
}
