import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../bug_reporter.dart';
import '../diagnostics/dio_client.dart';

class ImageUploadService {
  final Dio _dio;

  ImageUploadService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<String?> upload(
    Uint8List bytes, {
    String contentType = 'image/png',
  }) async {
    final cfg = BugReporter.config.imageUpload;
    if (cfg == null || !cfg.isConfigured) {
      debugPrint('[bug_reporter] imageUpload not configured');
      return null;
    }

    final key = _objectKey(cfg.keyPrefix);
    final String putUrl;
    String? serverViewUrl;

    try {
      final presign = await _dio.post(
        cfg.url,
        queryParameters: {'key': key},
        options: Options(
          headers: {if (cfg.apiKey.isNotEmpty) 'x-api-key': cfg.apiKey},
        ),
      );
      final url = _readUrl(presign.data);
      serverViewUrl = _readViewUrl(presign.data);
      debugPrint(
          '[bug_reporter] presign status=${presign.statusCode} url=${url != null ? 'received' : 'MISSING'}');
      if (url == null || url.isEmpty) {
        debugPrint('[bug_reporter] presign body: ${presign.data}');
        return null;
      }
      putUrl = url;
    } on DioException catch (e) {
      debugPrint(
          '[bug_reporter] presign FAILED status=${e.response?.statusCode} type=${e.type.name} body=${e.response?.data} msg=${e.message}');
      return null;
    }

    try {
      final put = await _dio.put(
        putUrl,
        data: Stream<List<int>>.fromIterable([bytes]),
        options: Options(
          contentType: contentType,
          headers: {Headers.contentLengthHeader: bytes.length},
        ),
      );
      final code = put.statusCode ?? 0;
      debugPrint('[bug_reporter] S3 PUT status=$code');
      if (code < 200 || code >= 300) return null;
    } on DioException catch (e) {
      debugPrint(
          '[bug_reporter] S3 PUT FAILED status=${e.response?.statusCode} type=${e.type.name} body=${e.response?.data} msg=${e.message}');
      return null;
    }

    final viewUrl = serverViewUrl ??
        (cfg.publicBaseUrl.isNotEmpty
            ? '${cfg.publicBaseUrl.replaceAll(RegExp(r'/+$'), '')}/$key'
            : '${cfg.url.replaceAll(RegExp(r'/+$'), '')}?key=$key');
    debugPrint('[bug_reporter] image view url=$viewUrl');
    return viewUrl;
  }

  String? _readUrl(dynamic data) => _field(data, const ['url', 'uploadUrl']);

  String? _readViewUrl(dynamic data) =>
      _field(data, const ['getUrl', 'viewUrl', 'downloadUrl']);

  String? _field(dynamic data, List<String> keys) {
    Map? map;
    if (data is Map) {
      map = data;
    } else if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) map = decoded;
      } catch (_) {}
    }
    if (map == null) return null;
    for (final k in keys) {
      final v = map[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  String _objectKey(String prefix) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final cleaned = prefix.replaceAll(RegExp(r'/+$'), '');
    final dir = cleaned.isEmpty ? '' : '$cleaned/';
    return '${dir}screenshot-$ts.png';
  }
}
