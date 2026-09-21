import 'dart:typed_data';

import '../bug_reporter.dart';
import '../diagnostics/breadcrumb.dart';

class BugReportDraft {
  final Uint8List screenshot;
  final List<Breadcrumb> breadcrumbs;
  final Map<String, dynamic> deviceInfo;
  final DateTime capturedAt;
  final String currentScreen;

  const BugReportDraft({
    required this.screenshot,
    required this.breadcrumbs,
    required this.deviceInfo,
    required this.capturedAt,
    required this.currentScreen,
  });
}

class BugReportPayload {
  final String description;
  final String title;
  final String expectedResults;
  final String actualResults;
  final List<Breadcrumb> breadcrumbs;
  final Map<String, dynamic> deviceInfo;
  final DateTime capturedAt;
  final int screenshotBytes;
  final String? screenshotKey;
  final String screenshotContentType;
  final String currentScreen;

  const BugReportPayload({
    required this.description,
    this.title = '',
    this.expectedResults = '',
    this.actualResults = '',
    required this.breadcrumbs,
    required this.deviceInfo,
    required this.capturedAt,
    required this.screenshotBytes,
    this.screenshotKey,
    this.screenshotContentType = 'image/png',
    required this.currentScreen,
  });

  factory BugReportPayload.fromDraft(
    BugReportDraft draft,
    String description, {
    String title = '',
    String expectedResults = '',
    String actualResults = '',
    String? screenshotKey,
    String screenshotContentType = 'image/png',
  }) {
    return BugReportPayload(
      description: description,
      title: title,
      expectedResults: expectedResults,
      actualResults: actualResults,
      breadcrumbs: draft.breadcrumbs,
      deviceInfo: draft.deviceInfo,
      capturedAt: draft.capturedAt,
      screenshotBytes: draft.screenshot.length,
      screenshotKey: screenshotKey,
      screenshotContentType: screenshotContentType,
      currentScreen: draft.currentScreen,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': kBugReportSchemaVersion,
        'description': description,
        if (title.isNotEmpty) 'title': title,
        if (expectedResults.isNotEmpty) 'expectedResults': expectedResults,
        if (actualResults.isNotEmpty) 'actualResults': actualResults,
        'currentScreen': currentScreen,
        'capturedAt': capturedAt.toIso8601String(),
        'screenshot': {
          'bytes': screenshotBytes,
          'contentType': screenshotContentType,
          if (screenshotKey != null) 'key': screenshotKey,
        },
        'deviceInfo': deviceInfo,
        'breadcrumbs': breadcrumbs.map((b) => b.toJson()).toList(),
      };
}
