import 'package:audio_diaries_flutter/core/diagnostics/debug_trace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DebugTrace', () {
    test('current is null outside a trace', () {
      expect(DebugTrace.current, isNull);
    });

    test('run binds the trace for async code inside it', () async {
      final trace = DebugTrace('op');

      final seen = await trace.run(() async {
        await Future<void>.delayed(Duration.zero);
        return DebugTrace.current;
      });

      expect(seen, same(trace));
      expect(DebugTrace.current, isNull);
    });

    test('concurrent traces stay separate', () async {
      final a = DebugTrace('a');
      final b = DebugTrace('b');

      await Future.wait([
        a.run(() async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          DebugTrace.current?.step('from_a');
        }),
        b.run(() async {
          DebugTrace.current?.step('from_b');
        }),
      ]);

      expect(a.events.map((e) => e.step), ['from_a']);
      expect(b.events.map((e) => e.step), ['from_b']);
    });

    test('fail defaults to the current step', () {
      final trace = DebugTrace('op')
        ..step('upload_files')
        ..fail('Rejected', statusCode: 403, responseBody: 'Forbidden');

      final root = trace.rootFailure!;
      expect(trace.hasFailed, isTrue);
      expect(root.step, 'upload_files');
      expect(root.message, 'Rejected');
      expect(root.data, {'status': '403', 'response': 'Forbidden'});
    });

    test('rootFailure is the first failure, not later knock-on ones', () {
      final trace = DebugTrace('op')
        ..fail('First', step: 'presigned_url')
        ..fail('Second', step: 'upload_files');

      expect(trace.failures, hasLength(2));
      expect(trace.rootFailure!.message, 'First');
    });

    test('long response bodies are truncated', () {
      final trace = DebugTrace('op')
        ..fail('Rejected', responseBody: 'x' * 2000);

      final response = trace.rootFailure!.data['response']!;
      expect(response.length, lessThan(DebugTrace.maxBodyLength + 30));
      expect(response, endsWith('(2000 chars)'));
    });

    test('toReport includes the failure, context, timeline and stack trace',
        () {
      final trace = DebugTrace('diary_submission',
          context: {'DiaryID': '42'}, now: DateTime.now());
      trace
        ..step('upload_responses')
        ..fail('Request failed',
            error: StateError('boom'), stackTrace: StackTrace.current);

      final report = trace.toReport();
      expect(report, contains('Fabla debug trace: diary_submission'));
      expect(report, contains('FAILED at: upload_responses'));
      expect(report, contains('Reason: Request failed'));
      expect(report, contains('DiaryID: 42'));
      expect(report, contains('error: StateError: Bad state: boom'));
      expect(report, contains('Stack trace:'));
    });

    test('a successful trace reports no failure', () {
      final trace = DebugTrace('op')..step('done');

      expect(trace.hasFailed, isFalse);
      expect(trace.toReport(), isNot(contains('FAILED')));
    });
  });
}
