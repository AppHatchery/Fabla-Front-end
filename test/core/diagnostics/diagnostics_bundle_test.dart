import 'dart:convert';

import 'package:audio_diaries_flutter/core/diagnostics/diagnostics_bundle.dart';
import 'package:audio_diaries_flutter/core/diagnostics/local_data.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:flutter_test/flutter_test.dart';

DiarySummary _diary(int id, DateTime start,
        {DiaryStatus status = DiaryStatus.idle,
        List<PromptSummary> prompts = const []}) =>
    DiarySummary(
      id: id,
      studyID: 7,
      name: 'Diary $id',
      start: start,
      end: start.add(const Duration(hours: 20)),
      due: start.add(const Duration(hours: 24)),
      status: status,
      entries: 1,
      currentEntry: 0,
      activeDays: null,
      submissions: const [],
      completions: const [],
      notifications: 2,
      prompts: prompts,
    );

void main() {
  final appDate = DateTime(2026, 10, 16, 10);

  final audio = PromptSummary(
    id: 1,
    questionNumber: 1,
    question: 'How was your day?',
    type: 'audio',
    required: true,
    answerCount: 1,
    answeredCurrent: true,
    recordings: const [
      RecordingFile(type: 'audio', path: 'recordings/a.m4a', bytes: 2048),
      RecordingFile(type: 'audio', path: 'recordings/b.m4a'),
    ],
  );

  final data = LocalData(
    participantId: 'P123',
    experiment: const {'login': 'TRAM', 'name': 'Tram', 'version': '3'},
    protocol: const {'version': 2},
    studies: const [
      StudySummary(id: 7, name: 'Daily', experimentCode: 'X', goals: null),
    ],
    diaries: [
      _diary(1, appDate.subtract(const Duration(days: 60)),
          status: DiaryStatus.submitted),
      _diary(2, appDate, status: DiaryStatus.complete, prompts: [audio]),
      _diary(3, appDate.add(const Duration(days: 30))),
    ],
  );

  Map<String, dynamic> build() => DiagnosticsBundle.build(
        generatedAt: appDate,
        appDate: appDate,
        data: data,
      );

  test('includes recent and pending diaries in full, every row compactly', () {
    final bundle = build();

    expect([for (final d in bundle['diaries_recent']) d['id']], [2]);
    expect(bundle['diaries_all'], hasLength(3));
    expect(bundle['diaries_all'][0], [
      1,
      7,
      appDate.subtract(const Duration(days: 60)).toIso8601String(),
      'submitted',
      '0/1',
    ]);
  });

  test('summarises the pending queue with recording sizes', () {
    final pending = build()['pending'] as List;

    expect(pending.single, {
      'id': 2,
      'name': 'Diary 2',
      'entry': '1/1',
      'recordings': 2,
      'recording_bytes': 2048,
      'missing_recordings': 1,
    });
  });

  test('summarises each study', () {
    final study = (build()['studies'] as List).single as Map;

    expect(study['rows'], 3);
    expect(study['status_counts'], {'idle': 1, 'complete': 1, 'submitted': 1});
  });

  test('carries no answer content or question text', () {
    final json = jsonEncode(build());

    expect(json, isNot(contains('How was your day?')));
    expect(json, contains('a.m4a'));
    expect(json, isNot(contains('recordings/a.m4a')));
  });
}
