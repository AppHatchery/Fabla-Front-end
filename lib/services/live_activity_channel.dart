import 'package:flutter/services.dart';

/// The `diary/live_activity` channel, shared by the timer and recording Live
/// Activities (ios/Runner/AppDelegate.swift).
///
/// A channel takes one handler, so each service registers the calls it
/// answers here instead of replacing the other's.
class LiveActivityChannel {
  static const channel = MethodChannel('diary/live_activity');

  static final _handlers = <String, Future<dynamic> Function()>{};

  /// Answers [method] with [handler] until [off].
  static void on(String method, Future<dynamic> Function() handler) {
    _handlers[method] = handler;
    channel.setMethodCallHandler(_dispatch);
  }

  /// Stops answering [method]. Given a [handler], only if it is still the
  /// one registered, so a newer owner of the call keeps it.
  static void off(String method, [Future<dynamic> Function()? handler]) {
    // Tear-offs of one method on one object are equal, not identical.
    if (handler != null && _handlers[method] != handler) return;
    _handlers.remove(method);
  }

  static Future<dynamic> _dispatch(MethodCall call) async =>
      _handlers[call.method]?.call();
}
