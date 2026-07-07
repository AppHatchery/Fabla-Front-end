import 'package:flutter/foundation.dart';

/// Ensures only one async operation runs at a time. Concurrent calls while
/// one is in flight are dropped. Errors go to [onError], never rethrown.
///
/// O(1).
class PermissionRequestGuard {
  PermissionRequestGuard({void Function(Object error)? onError})
      : _onError = onError ?? _logError;

  final void Function(Object error) _onError;
  bool _isRunning = false;

  /// True while an operation is in flight.
  bool get isRunning => _isRunning;

  /// Runs [action] if nothing else is running. No-op otherwise.
  Future<void> run(Future<void> Function() action) async {
    if (_isRunning) return;
    _isRunning = true;
    try {
      await action();
    } catch (error) {
      _onError(error);
    } finally {
      _isRunning = false;
    }
  }

  static void _logError(Object error) =>
      debugPrint('Permission request failed: $error');
}