import 'package:bug_reporter/bug_reporter.dart';
import 'package:bug_reporter/src/diagnostics/breadcrumb.dart';
import 'package:bug_reporter/src/diagnostics/breadcrumb_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    BugReporter.init(const BugReporterConfig(
      routeNames: {
        '/': 'Home',
        '/tasks/edit': 'Edit Task',
        '/profile': 'Profile',
      },
    ));
  });

  test('friendlyRoute uses exact match, then prefix, then fallbacks', () {
    expect(BreadcrumbFormatter.friendlyRoute('/profile'), 'Profile');
    expect(BreadcrumbFormatter.friendlyRoute('/tasks/edit/42'), 'Edit Task');
    expect(BreadcrumbFormatter.friendlyRoute('/'), 'Home');
    expect(BreadcrumbFormatter.friendlyRoute(null), 'the app');
    expect(BreadcrumbFormatter.friendlyRoute('/unmapped'), '/unmapped');
  });

  test('describe turns a navigation push into a sentence', () {
    final crumb = Breadcrumb(
      category: BreadcrumbCategory.navigation,
      event: 'push',
      data: {'to': '/tasks/edit/42', 'from': '/'},
    );
    expect(BreadcrumbFormatter.describe(crumb), 'Opened Edit Task');
  });

  test('describe names a tap target', () {
    final crumb = Breadcrumb(
      category: BreadcrumbCategory.tap,
      event: 'tap',
      data: {'target': 'Save'},
    );
    expect(BreadcrumbFormatter.describe(crumb), "Tapped 'Save'");
  });
}
