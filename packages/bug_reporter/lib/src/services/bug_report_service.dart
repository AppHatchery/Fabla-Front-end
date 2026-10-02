import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../bug_reporter.dart';
import '../diagnostics/dio_client.dart';
import '../models/bug_report_payload.dart';

class BugReportException implements Exception {
  final String message;

  BugReportException(this.message);

  @override
  String toString() => message;
}

class BugReportService {
  final Dio _dio;

  BugReportService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  /// Best-effort screenshot upload. Requests a presigned URL from the backend,
  /// PUTs the bytes straight to storage, and returns the object key. Returns
  /// null on any failure (or when uploads are not configured) so the report is
  /// still submitted without an image.
  Future<String?> uploadScreenshot(
    Uint8List bytes, {
    String contentType = 'image/png',
  }) async {
    final config = BugReporter.config;
    if (!config.isBackendConfigured) return null;

    try {
      final presign = await _dio.post(
        '${config.backendBaseUrl}/uploads',
        data: {'contentType': contentType, 'ext': 'png'},
        options: Options(headers: {'x-api-key': config.apiKey}),
      );

      final data = presign.data;
      if (data is! Map) return null;
      final uploadUrl = data['uploadUrl'] as String?;
      final key = data['key'] as String?;
      if (uploadUrl == null || key == null) return null;

      final put = await _dio.put(
        uploadUrl,
        data: Stream<List<int>>.fromIterable([bytes]),
        options: Options(
          contentType: contentType,
          headers: {Headers.contentLengthHeader: bytes.length},
        ),
      );

      final code = put.statusCode ?? 0;
      return (code >= 200 && code < 300) ? key : null;
    } on DioException {
      return null;
    }
  }

  Future<String> submit(BugReportPayload payload) async {
    final config = BugReporter.config;
    if (!config.isBackendConfigured) {
      throw BugReportException('Backend URL or API key is not configured.');
    }

    final body = payload.toJson();
    final data = config.scrub?.call(body) ?? body;

    try {
      final response = await _dio.post(
        '${config.backendBaseUrl}/reports',
        data: data,
        options: Options(headers: {'x-api-key': config.apiKey}),
      );

      final responseData = response.data;
      final issueUrl =
          responseData is Map ? responseData['issueUrl'] as String? : null;
      if (issueUrl == null || issueUrl.isEmpty) {
        throw BugReportException('Server did not return an issue URL.');
      }
      return issueUrl;
    } on DioException catch (e) {
      throw BugReportException(_messageFor(e));
    }
  }

  String _messageFor(DioException e) {
    final code = e.response?.statusCode;
    switch (code) {
      case 401:
        return 'The backend rejected the API key.';
      case 400:
        return 'The report was rejected as invalid.';
      case 502:
        return 'The backend could not create the GitHub issue.';
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Could not reach the backend. Is it running and reachable?';
    }
    return 'Failed to submit the report (${code ?? e.type.name}).';
  }
}
