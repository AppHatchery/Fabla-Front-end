import 'dart:typed_data';

import 'package:bug_reporter/src/diagnostics/breadcrumb.dart';
import 'package:bug_reporter/src/models/bug_report_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BugReportDraft draft() => BugReportDraft(
        screenshot: Uint8List.fromList(List.filled(120, 0)),
        breadcrumbs: [
          Breadcrumb(category: BreadcrumbCategory.tap, event: 'tap', data: {'target': 'Save'}),
        ],
        deviceInfo: {'model': 'Pixel'},
        capturedAt: DateTime.utc(2026, 8, 9, 14, 22, 24),
        currentScreen: 'Home',
      );

  test('toJson emits the v1 schema with a screenshot object', () {
    final json = BugReportPayload.fromDraft(draft(), 'It broke').toJson();
    expect(json['schemaVersion'], 1);
    expect(json['description'], 'It broke');
    expect(json['currentScreen'], 'Home');
    expect(json['capturedAt'], '2026-08-09T14:22:24.000Z');
    expect(json['screenshot'], {'bytes': 120, 'contentType': 'image/png'});
    expect(json['deviceInfo'], {'model': 'Pixel'});
    expect((json['breadcrumbs'] as List).single['category'], 'tap');
  });

  test('the screenshot key is included only once uploaded', () {
    final json = BugReportPayload.fromDraft(
      draft(),
      'x',
      screenshotKey: 'reports/2026/08/09/abc.png',
    ).toJson();
    final screenshot = json['screenshot'] as Map<String, dynamic>;
    expect(screenshot['key'], 'reports/2026/08/09/abc.png');
    expect(screenshot['bytes'], 120);
  });
}
