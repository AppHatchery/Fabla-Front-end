import 'dart:async';
import 'dart:io' show HttpDate;

import 'package:audio_diaries_flutter/core/diagnostics/debug_trace.dart';
import 'package:audio_diaries_flutter/core/network/tracing_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final now = DateTime.utc(2026, 10, 16, 12);
  final url = Uri.parse(
      'https://bucket.s3.amazonaws.com/STUDY/Audios/PARTICIPANT123_file.m4a?X-Amz-Signature=secret');

  TracingClient tracing(MockClientHandler handler) =>
      TracingClient(MockClient(handler), now: () => now);

  Future<DebugTrace> traced(Future<void> Function() body) async {
    final trace = DebugTrace('test');
    await trace.run(body);
    return trace;
  }

  test('outside a trace it passes requests straight through', () async {
    final response =
        await tracing((_) async => http.Response('ok', 200)).get(url);

    expect(response.statusCode, 200);
  });

  test('records method, host, status and AWS request id', () async {
    final client = tracing((_) async => http.Response('ok', 200, headers: {
          'x-amz-request-id': 'S3REQ123',
          'date': HttpDate.format(now),
        }));

    final trace = await traced(() => client.put(url, body: 'x'));

    final note = trace.events.single;
    expect(note.isNote, isTrue);
    expect(note.message,
        matches(r'^PUT bucket\.s3\.amazonaws\.com → 200 \(\d+ms\)$'));
    expect(note.data['x-amz-request-id'], 'S3REQ123');
    expect(note.data['sent'], '1 B');
  });

  test('never records the path or query (participant ID, signature)', () async {
    final client = tracing((_) async => http.Response('ok', 200));

    final trace = await traced(() => client.put(url, body: 'x'));

    final report = trace.toReport();
    expect(report, isNot(contains('PARTICIPANT123')));
    expect(report, isNot(contains('secret')));
  });

  test('records upload speed for large bodies', () async {
    final client = tracing((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return http.Response('ok', 200);
    });

    final trace =
        await traced(() => client.put(url, body: List.filled(256 * 1024, 0)));

    final data = trace.events.single.data;
    expect(data['sent'], '256.0 KB');
    expect(data['speed'], endsWith('/s'));
  });

  test('a clock in sync is noted in the context without a warning', () async {
    final client = tracing((_) async => http.Response('ok', 200, headers: {
          'date': HttpDate.format(now.add(const Duration(seconds: 1)))
        }));

    final trace = await traced(() => client.get(url));

    expect(trace.context['Clock vs server'], 'in sync');
    expect(trace.events.single.data.containsKey('clock_skew'), isFalse);
  });

  test('a device clock a day ahead is flagged', () async {
    final client = tracing((_) async => http.Response('', 403, headers: {
          'date': HttpDate.format(now.subtract(const Duration(days: 1))),
        }));

    final trace = await traced(() => client.get(url));

    expect(trace.context['Clock vs server'], 'device 1d ahead');
    expect(trace.events.single.data['clock_skew'],
        startsWith('device 1d ahead — AWS may reject'));
  });

  test('a failed attempt is noted and rethrown', () async {
    final client = tracing((_) async => throw TimeoutException('slow'));

    final trace = DebugTrace('test');
    await expectLater(
        trace.run(() => client.get(url)), throwsA(isA<TimeoutException>()));

    expect(trace.events.single.message, matches(r'→ timed out \(\d+ms\)$'));
  });

  test('notes do not change the current step', () async {
    final client = tracing((_) async => http.Response('ok', 200));
    final trace = DebugTrace('test')..step('presigned_url');

    await trace.run(() => client.get(url));
    trace.fail('Rejected');

    expect(trace.rootFailure!.step, 'presigned_url');
  });

  group('describeSkew', () {
    test('formats ahead and behind', () {
      expect(TracingClient.describeSkew(const Duration(hours: 26, minutes: 5)),
          'device 1d 2h 5m ahead');
      expect(TracingClient.describeSkew(const Duration(minutes: -6)),
          'device 6m behind');
      expect(TracingClient.describeSkew(const Duration(seconds: 42)),
          'device 42s ahead');
    });
  });
}
