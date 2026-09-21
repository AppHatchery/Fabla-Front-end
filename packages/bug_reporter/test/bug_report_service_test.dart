import 'dart:convert';
import 'dart:typed_data';

import 'package:bug_reporter/bug_reporter.dart';
import 'package:bug_reporter/src/models/bug_report_payload.dart';
import 'package:bug_reporter/src/services/bug_report_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({this.reportsStatus = 201, this.uploadsStatus = 201, this.putStatus = 200});

  final int reportsStatus;
  final int uploadsStatus;
  final int putStatus;
  Map<String, dynamic>? lastReportBody;

  ResponseBody _json(Object data, int status) => ResponseBody.fromString(
        jsonEncode(data),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'PUT') {
      return ResponseBody.fromString('', putStatus);
    }
    final path = options.uri.path;
    if (path.endsWith('/uploads')) {
      return _json(
        {'uploadUrl': 'https://s3.test/upload?sig=1', 'key': 'reports/2026/01/01/x.png', 'expiresIn': 300},
        uploadsStatus,
      );
    }
    if (path.endsWith('/reports')) {
      lastReportBody = options.data is Map ? Map<String, dynamic>.from(options.data as Map) : null;
      return _json({'status': 'created', 'issueUrl': 'https://gh/issues/1', 'issueNumber': 1}, reportsStatus);
    }
    return _json({}, 404);
  }

  @override
  void close({bool force = false}) {}
}

BugReportPayload _payload() => BugReportPayload(
      description: 'It broke',
      breadcrumbs: const [],
      deviceInfo: const {'model': 'Pixel'},
      capturedAt: DateTime.utc(2026, 8, 9),
      screenshotBytes: 120,
      currentScreen: 'Home',
    );

BugReportService _service(_FakeAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return BugReportService(dio: dio);
}

void main() {
  setUp(() {
    BugReporter.init(const BugReporterConfig(
      backendBaseUrl: 'https://api.test',
      apiKey: 'k',
    ));
  });

  test('submit posts the v1 payload and returns the issue url', () async {
    final adapter = _FakeAdapter();
    final url = await _service(adapter).submit(_payload());
    expect(url, 'https://gh/issues/1');
    expect(adapter.lastReportBody?['schemaVersion'], 1);
    expect((adapter.lastReportBody?['screenshot'] as Map)['bytes'], 120);
  });

  test('submit maps a 502 to a BugReportException', () async {
    final service = _service(_FakeAdapter(reportsStatus: 502));
    expect(() => service.submit(_payload()), throwsA(isA<BugReportException>()));
  });

  test('uploadScreenshot returns the key on success', () async {
    final key = await _service(_FakeAdapter()).uploadScreenshot(Uint8List.fromList([1, 2, 3]));
    expect(key, 'reports/2026/01/01/x.png');
  });

  test('uploadScreenshot returns null when uploads are unavailable', () async {
    final key = await _service(_FakeAdapter(uploadsStatus: 503)).uploadScreenshot(Uint8List.fromList([1, 2, 3]));
    expect(key, isNull);
  });

  test('submit throws when the backend is not configured', () async {
    BugReporter.init(const BugReporterConfig());
    expect(() => _service(_FakeAdapter()).submit(_payload()), throwsA(isA<BugReportException>()));
  });
}
