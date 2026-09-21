import 'package:flutter/widgets.dart';

import '../bug_reporter.dart';
import 'breadcrumbs.dart';

class BreadcrumbNavigatorObserver extends NavigatorObserver {
  String _name(Route<dynamic>? route) {
    if (route == null) return 'unknown';
    return Breadcrumbs.instance.routeName(route) ??
        route.settings.name ??
        route.runtimeType.toString();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final to = _name(route);
    if (to != kBugReportRouteName) {
      Breadcrumbs.instance.setRouteScreen(route.isFirst ? null : to);
    }
    Breadcrumbs.instance.navigation('push', data: {
      'to': to,
      'from': _name(previousRoute),
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final to = _name(previousRoute);
    if (_name(route) != kBugReportRouteName) {
      Breadcrumbs.instance
          .setRouteScreen((previousRoute?.isFirst ?? true) ? null : to);
    }
    Breadcrumbs.instance.navigation('pop', data: {
      'from': _name(route),
      'to': to,
    });
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final to = _name(newRoute);
    if (to != kBugReportRouteName) {
      Breadcrumbs.instance
          .setRouteScreen((newRoute?.isFirst ?? false) ? null : to);
    }
    Breadcrumbs.instance.navigation('replace', data: {
      'from': _name(oldRoute),
      'to': to,
    });
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    Breadcrumbs.instance.navigation('remove', data: {
      'removed': _name(route),
    });
  }
}
