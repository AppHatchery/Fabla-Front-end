import 'package:audio_diaries_flutter/core/diagnostics/debug_trace.dart';
import 'package:audio_diaries_flutter/core/diagnostics/trace_log.dart';
import 'package:audio_diaries_flutter/services/developer_mode_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final log = TraceLog();

  DebugTrace failed(String reason, {String diary = 'Daily'}) =>
      DebugTrace('diary_submission', context: {'Diary': diary})
        ..step('upload_responses')
        ..fail(reason, statusCode: 500);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores a failed trace with its step, reason and report', () async {
    final trace = failed('Rejected');
    await log.add(trace);

    final records = await log.load();
    expect(records, hasLength(1));
    final record = records.single;
    expect(record.step, 'upload_responses');
    expect(record.reason, 'Rejected');
    expect(record.diary, 'Daily');
    expect(record.simulated, isFalse);
    expect(record.time, trace.rootFailure!.time);
    expect(record.report, trace.toReport());
  });

  test('ignores traces that did not fail', () async {
    await log.add(DebugTrace('diary_submission')..step('connectivity'));

    expect(await log.load(), isEmpty);
  });

  test('lists newest first and keeps only the most recent', () async {
    for (var i = 0; i < TraceLog.maxRecords + 3; i++) {
      await log.add(failed('Failure $i'));
    }

    final records = await log.load();
    expect(records, hasLength(TraceLog.maxRecords));
    expect(records.first.reason, 'Failure ${TraceLog.maxRecords + 2}');
    expect(records.last.reason, 'Failure 3');
  });

  test('records added back to back are all kept', () async {
    await Future.wait([log.add(failed('A')), log.add(failed('B'))]);

    expect((await log.load()).map((r) => r.reason), ['B', 'A']);
  });

  test('marks simulated failures', () async {
    SharedPreferences.setMockInitialValues({});
    await DeveloperModeService().enable();
    addTearDown(DeveloperModeService().disable);
    DeveloperModeService().simulateNextFailure(SimulatedFailure.noInternet);
    final trace = DebugTrace('diary_submission');
    await trace.run(() async {
      DeveloperModeService().consumeSimulated(SimulatedFailure.noInternet);
      trace.fail('No internet connection (simulated)');
    });

    await log.add(trace);

    expect((await log.load()).single.simulated, isTrue);
  });

  test('clear removes every record', () async {
    await log.add(failed('Rejected'));
    await log.clear();

    expect(await log.load(), isEmpty);
  });

  test('skips entries it cannot read', () async {
    SharedPreferences.setMockInitialValues({
      TraceLog.preferenceKey: ['not json', '{"time": "bad"}'],
    });
    await log.add(failed('Rejected'));

    expect((await log.load()).single.reason, 'Rejected');
  });

  test('keeps the diary id from the trace context', () async {
    await log.add(DebugTrace('diary_submission',
        context: {'Diary': 'Daily', 'DiaryID': '42'})
      ..fail('Rejected'));

    expect((await log.load()).single.diaryId, 42);
  });
}
