import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import 'debug_trace.dart';

/// Records app lifecycle changes (backgrounded, suspended, resumed) and
/// connectivity changes (Wi-Fi to cellular, offline) on [trace] while [body]
/// runs. These explain failures that start mid-submission, e.g. airplane
/// mode or iOS suspending the app during an upload.
///
/// Passive: only listens, so it is safe to run for every submission.
Future<T> watchDuring<T>(
  DebugTrace trace,
  Future<T> Function() body, {
  Stream<List<ConnectivityResult>>? connectivityChanges,
  Stream<AppLifecycleState>? lifecycleChanges,
}) async {
  final subscriptions = <StreamSubscription<Object?>>[];
  AppLifecycleListener? lifecycleListener;
  StreamController<AppLifecycleState>? lifecycleController;

  if (lifecycleChanges == null) {
    try {
      lifecycleController = StreamController<AppLifecycleState>();
      final controller = lifecycleController;
      lifecycleListener = AppLifecycleListener(onStateChange: controller.add);
      lifecycleChanges = controller.stream;
    } catch (_) {
      // No widgets binding (e.g. some unit tests): skip lifecycle tracking.
    }
  }

  try {
    connectivityChanges ??= Connectivity().onConnectivityChanged;
  } catch (_) {}

  if (lifecycleChanges != null) {
    subscriptions.add(lifecycleChanges.listen(
      (state) => trace.note('App ${state.name}'),
      onError: (_) {},
    ));
  }

  if (connectivityChanges != null) {
    String? last;
    subscriptions.add(connectivityChanges.listen(
      (results) {
        final current = results.map((r) => r.name).join(', ');
        // Platforms may re-emit the same state; only record changes.
        if (current == last) return;
        trace.note(last == null
            ? 'Connectivity: $current'
            : 'Connectivity changed: $last → $current');
        last = current;
      },
      onError: (_) {}, // e.g. no plugin in tests
    ));
  }

  try {
    return await body();
  } finally {
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    lifecycleListener?.dispose();
    await lifecycleController?.close();
  }
}
