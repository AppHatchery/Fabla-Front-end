import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'breadcrumb.dart';

class Breadcrumbs {
  Breadcrumbs._();

  static final Breadcrumbs instance = Breadcrumbs._();

  static const int maxEntries = 50;

  final Queue<Breadcrumb> _buffer = Queue<Breadcrumb>();

  final Expando<String> _routeNames = Expando<String>();

  String? _routeScreen;
  String? _appScreen;

  /// The screen the report should show: the pushed route if one is on top,
  /// otherwise the screen the app last set (e.g. the active tab).
  String get currentScreen => _routeScreen ?? _appScreen ?? 'unknown';

  /// Set by the app for screens the Navigator can't see, such as tabs.
  void setScreen(String name) => _appScreen = name;

  void setRouteScreen(String? name) => _routeScreen = name;

  void setRouteName(Route<dynamic> route, String name) =>
      _routeNames[route] = name;

  String? routeName(Route<dynamic>? route) =>
      route == null ? null : _routeNames[route];

  void log(
    BreadcrumbCategory category,
    String event, {
    Map<String, dynamic>? data,
  }) {
    _buffer.addLast(Breadcrumb(category: category, event: event, data: data));
    while (_buffer.length > maxEntries) {
      _buffer.removeFirst();
    }
  }

  void navigation(String event, {Map<String, dynamic>? data}) =>
      log(BreadcrumbCategory.navigation, event, data: data);

  void tap(String event, {Map<String, dynamic>? data}) =>
      log(BreadcrumbCategory.tap, event, data: data);

  void network(String event, {Map<String, dynamic>? data}) =>
      log(BreadcrumbCategory.network, event, data: data);

  void lifecycle(String event, {Map<String, dynamic>? data}) =>
      log(BreadcrumbCategory.lifecycle, event, data: data);

  void custom(String event, {Map<String, dynamic>? data}) =>
      log(BreadcrumbCategory.custom, event, data: data);

  List<Breadcrumb> snapshot() => List<Breadcrumb>.unmodifiable(_buffer);

  int get length => _buffer.length;

  void clear() => _buffer.clear();

  String toJsonString() {
    final encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(_buffer.map((b) => b.toJson()).toList());
  }

  void dumpToConsole() {
    debugPrint('==== Breadcrumbs (${_buffer.length}) ====');
    debugPrint(toJsonString());
    debugPrint('==== End breadcrumbs ====');
  }
}
