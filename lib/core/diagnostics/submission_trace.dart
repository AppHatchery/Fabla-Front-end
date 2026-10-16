import 'package:flutter/foundation.dart';

import '../../screens/diary/data/diary.dart';
import '../../screens/diary/domain/repository/summary_repository.dart';
import '../utils/device_appInfo.dart';
import 'debug_trace.dart';
import 'trace_log.dart';
import 'trace_watchers.dart';

/// Metadata describing [diary] and the device for a submission trace.
/// No participant identifiers or response content.
Future<Map<String, String>> submissionTraceContext(DiaryModel diary) async {
  String appVersion;
  try {
    appVersion = await getAppVersion();
  } catch (_) {
    appVersion = 'unknown';
  }
  final answered = diary.prompts.where((p) => p.answer != null).length;
  return {
    'Diary': diary.name,
    'DiaryID': diary.id.toString(),
    'StudyID': diary.studyID.toString(),
    'Entry': '${diary.currentEntry + 1}/${diary.entries}',
    'Status': diary.status.name,
    'Prompts answered': '$answered/${diary.prompts.length}',
    'App version': appVersion,
    'Platform': defaultTargetPlatform.name,
  };
}

/// Submits [diary] (loaded with its answers) under a [DebugTrace], the way
/// the summary page does, and stores the trace in [TraceLog] if it fails.
/// For developer mode's retry from the pending queue.
///
/// Returns [SummaryRepository.submitDiary]'s result: true sent, false
/// failed, null not sent (no internet).
Future<({bool? result, DebugTrace trace})> submitWithTrace(
  DiaryModel diary, {
  SummaryRepository? repository,
  String source = 'Developer mode queue',
}) async {
  final summaryRepository = repository ?? SummaryRepository();
  final trace = DebugTrace('diary_submission');
  bool? result;
  try {
    trace.context
      ..addAll(await submissionTraceContext(diary))
      ..['Source'] = source;
    result = await trace.run(
        () => watchDuring(trace, () => summaryRepository.submitDiary(diary)));
    if (result == true) {
      await summaryRepository.calculateEarnedIncentives(diary);
    } else if (!trace.hasFailed) {
      trace.fail('Submission returned false without a recorded reason');
    }
  } catch (e, stackTrace) {
    trace.fail('Unexpected exception retrying from the queue',
        error: e, stackTrace: stackTrace);
    result = false;
  }
  if (result != true) await TraceLog().add(trace);
  return (result: result, trace: trace);
}
