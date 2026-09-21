import '../bug_reporter.dart';
import 'breadcrumb.dart';

class BreadcrumbFormatter {
  BreadcrumbFormatter._();

  static String friendlyRoute(String? path) {
    if (path == null || path.isEmpty || path == 'unknown') return 'the app';

    final names = BugReporter.config.routeNames;
    final exact = names[path];
    if (exact != null) return exact;

    for (final entry in names.entries) {
      if (path.startsWith(entry.key)) return entry.value;
    }

    if (path == '/') return 'the app';
    return path;
  }

  static String describe(Breadcrumb crumb) {
    final data = crumb.data ?? const <String, dynamic>{};
    switch (crumb.category) {
      case BreadcrumbCategory.navigation:
        final to = friendlyRoute(data['to'] as String?);
        final from = friendlyRoute(data['from'] as String?);
        final removed = friendlyRoute(data['removed'] as String?);
        switch (crumb.event) {
          case 'push':
            return 'Opened $to';
          case 'pop':
            return 'Went back to $to';
          case 'replace':
            return 'Switched to $to';
          case 'remove':
            return 'Closed $removed';
          default:
            return 'Moved from $from to $to';
        }
      case BreadcrumbCategory.tap:
        final target = data['target'];
        if (target != null) return "Tapped '$target'";
        final dx = data['dx'];
        final dy = data['dy'];
        if (dx != null && dy != null) return 'Tapped screen at ($dx, $dy)';
        return 'Tapped screen';
      case BreadcrumbCategory.network:
        final method = data['method'] ?? 'HTTP';
        final path = data['path'] ?? '';
        final status = data['status'];
        if (crumb.event == 'error') {
          return '$method $path failed${status != null ? ' ($status)' : ''}';
        }
        final ms = data['durationMs'];
        final duration = ms != null ? ' · ${ms}ms' : '';
        return '$method $path → ${status ?? '?'}$duration';
      case BreadcrumbCategory.lifecycle:
        switch (crumb.event) {
          case 'resumed':
            return 'App returned to foreground';
          case 'paused':
            return 'App sent to background';
          case 'inactive':
            return 'App became inactive';
          case 'detached':
            return 'App detached';
          case 'hidden':
            return 'App hidden';
          default:
            return 'Lifecycle: ${crumb.event}';
        }
      case BreadcrumbCategory.custom:
        switch (crumb.event) {
          case 'bug_report_opened':
            return 'Started a bug report';
          case 'bug_report_submitted':
            return 'Submitted the bug report';
          case 'bug_report_capture_failed':
            return 'Screenshot capture failed';
          default:
            return crumb.event;
        }
    }
  }

  static String relativeTime(DateTime time, DateTime now) {
    final diff = now.difference(time);
    if (diff.isNegative || diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static String timeBucket(DateTime time, DateTime now) {
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 5) return 'A few minutes ago';
    if (diff.inMinutes < 30) return 'Earlier';
    return 'A while ago';
  }
}
