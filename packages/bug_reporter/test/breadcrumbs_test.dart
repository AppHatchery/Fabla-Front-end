import 'package:bug_reporter/bug_reporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => Breadcrumbs.instance.clear());

  test('the buffer is capped at maxEntries, keeping the newest', () {
    for (var i = 0; i < 60; i++) {
      Breadcrumbs.instance.custom('event_$i');
    }
    expect(Breadcrumbs.instance.length, Breadcrumbs.maxEntries);

    final crumbs = Breadcrumbs.instance.snapshot();
    expect(crumbs.first.event, 'event_10'); // 0..9 evicted
    expect(crumbs.last.event, 'event_59');
  });

  test('category helpers tag the crumb', () {
    Breadcrumbs.instance.navigation('push', data: {'to': '/'});
    Breadcrumbs.instance.tap('tap');
    final crumbs = Breadcrumbs.instance.snapshot();
    expect(crumbs[0].category, BreadcrumbCategory.navigation);
    expect(crumbs[1].category, BreadcrumbCategory.tap);
  });

  test('toJson carries timestamp, category, event and non-empty data', () {
    Breadcrumbs.instance.network('response', data: {'status': 200});
    final json = Breadcrumbs.instance.snapshot().single.toJson();
    expect(json['category'], 'network');
    expect(json['event'], 'response');
    expect(json['data'], {'status': 200});
    expect(json.containsKey('timestamp'), isTrue);
  });
}
