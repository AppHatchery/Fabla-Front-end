import 'dart:async';
import 'dart:io' show HttpDate;

import 'package:audio_diaries_flutter/core/diagnostics/debug_trace.dart';
import 'package:http/http.dart';

/// Records every HTTP attempt made inside a [DebugTrace]: method, host,
/// status, duration, bytes sent, upload speed, AWS request IDs, and the
/// device's clock skew against the server's `Date` header.
///
/// Sits under the retry layer so each attempt, timeouts included, is its own
/// note. Outside a trace it is a pass-through.
///
/// Only the host is recorded: S3 paths contain the participant ID and
/// presigned URLs carry signatures.
class TracingClient extends BaseClient {
  TracingClient(this._inner, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final Client _inner;
  final DateTime Function() _now;

  /// Response headers that identify the request in AWS logs.
  static const requestIdHeaders = [
    'x-amzn-requestid', // Lambda function URLs, API Gateway
    'apigw-requestid', // API Gateway HTTP APIs
    'x-amz-request-id', // S3
  ];

  /// Skew beyond this is called out: AWS rejects signatures more than five
  /// minutes off, and presigned URLs are checked against the clock.
  static const skewWarning = Duration(minutes: 5);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final trace = DebugTrace.current;
    if (trace == null) return _inner.send(request);

    final label = '${request.method} ${request.url.host}';
    final bytes = request.contentLength;
    final watch = Stopwatch()..start();
    try {
      final response = await _inner.send(request);
      final elapsed = watch.elapsed;
      trace.note(
          '$label → ${response.statusCode} (${elapsed.inMilliseconds}ms)',
          data: {
            if (bytes != null && bytes > 0) 'sent': _formatBytes(bytes),
            if (bytes != null && bytes >= 64 * 1024)
              'speed': _formatSpeed(bytes, elapsed),
            for (final header in requestIdHeaders)
              if (response.headers[header] case final id?) header: id,
            ..._clockSkew(trace, response.headers['date']),
          });
      return response;
    } catch (e) {
      trace.note('$label → ${_describe(e)} (${watch.elapsedMilliseconds}ms)',
          data: {
            if (bytes != null && bytes > 0) 'sent': _formatBytes(bytes),
          });
      rethrow;
    }
  }

  /// Compares the server's `Date` with the device clock. The first reading is
  /// added to the trace context; large skews are flagged on every response.
  Map<String, String> _clockSkew(DebugTrace trace, String? dateHeader) {
    if (dateHeader == null) return const {};
    final DateTime serverTime;
    try {
      serverTime = HttpDate.parse(dateHeader);
    } catch (_) {
      return const {};
    }
    final skew = _now().difference(serverTime);
    final summary = describeSkew(skew);
    trace.context.putIfAbsent('Clock vs server', () => summary);
    if (skew.abs() < skewWarning) return const {};
    return {
      'clock_skew': '$summary — AWS may reject signatures and presigned URLs',
    };
  }

  /// "in sync", or e.g. "device 1d 2h ahead" / "device 6m behind".
  static String describeSkew(Duration skew) {
    // The Date header has one-second resolution.
    if (skew.abs() < const Duration(seconds: 2)) return 'in sync';
    final direction = skew.isNegative ? 'behind' : 'ahead';
    final abs = skew.abs();
    final parts = [
      if (abs.inDays > 0) '${abs.inDays}d',
      if (abs.inHours % 24 > 0) '${abs.inHours % 24}h',
      if (abs.inMinutes % 60 > 0) '${abs.inMinutes % 60}m',
      if (abs.inHours == 0 && abs.inSeconds % 60 > 0) '${abs.inSeconds % 60}s',
    ];
    return 'device ${parts.join(' ')} $direction';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _formatSpeed(int bytes, Duration elapsed) {
    if (elapsed.inMilliseconds == 0) return 'n/a';
    final bytesPerSecond = bytes * 1000 / elapsed.inMilliseconds;
    return '${_formatBytes(bytesPerSecond.round())}/s';
  }

  static String _describe(Object error) =>
      error is TimeoutException ? 'timed out' : '${error.runtimeType}: $error';

  @override
  void close() => _inner.close();
}
