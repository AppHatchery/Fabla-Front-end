import 'dart:convert';

import 'package:audio_diaries_flutter/core/usecases/diary.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../dummy_data.dart';

class MockPreferenceService extends Mock implements PreferenceService {}

void main() {
  late MockPreferenceService mockPreferenceService;

  setUp(() {
    mockPreferenceService = MockPreferenceService();
    when(() => mockPreferenceService.setStringPreference(
        key: any(named: 'key'),
        value: any(named: 'value'))).thenAnswer((_) async => true);
  });

  void stubPreferences({Map<String, String>? starts, Map<String, String>? ends}) {
    when(() => mockPreferenceService.getStringPreference(key: 'diary_starts'))
        .thenAnswer((_) async => starts == null ? null : jsonEncode(starts));
    when(() => mockPreferenceService.getStringPreference(key: 'diary_ends'))
        .thenAnswer((_) async => ends == null ? null : jsonEncode(ends));
  }

  group('submitDiaryCompletionTime', () {
    final testDiary = createTestDiaryModel(id: 1, name: 'Test Diary');
    final testStudy = createTestStudyModel(name: 'Test Study');

    test(
        'returns start and end entries with diary name and study when both are saved',
        () async {
      // Arrange
      stubPreferences(
        starts: {'1': '2024-01-01T08:00:00.000'},
        ends: {'1': '2024-01-01T08:30:00.000'},
      );

      // Act
      final entries = await submitDiaryCompletionTime(
        diary: testDiary,
        study: testStudy,
        participantID: TestValues.testParticipantId,
        experimentCode: TestValues.testExperimentCode,
        promptLength: 3,
        preferenceService: mockPreferenceService,
      );

      // Assert
      expect(entries.length, equals(2));

      final start =
          entries.firstWhere((e) => e.questionsType == 'start_time');
      expect(start.diaryID, equals('1'));
      expect(start.diaryName, equals('Test Diary'));
      expect(start.study, equals('Test Study'));
      expect(start.response, equals('2024-01-01T08:00:00.000'));
      expect(start.promptID, equals('4')); // promptLength + 1

      final end = entries.firstWhere((e) => e.questionsType == 'end_time');
      expect(end.diaryID, equals('1'));
      expect(end.diaryName, equals('Test Diary'));
      expect(end.study, equals('Test Study'));
      expect(end.response, equals('2024-01-01T08:30:00.000'));
      expect(end.promptID, equals('5')); // promptLength + 2
    });

    test('falls back to "unknown" study when study is null', () async {
      // Arrange
      stubPreferences(starts: {'1': '2024-01-01T08:00:00.000'});

      // Act
      final entries = await submitDiaryCompletionTime(
        diary: testDiary,
        study: null,
        participantID: TestValues.testParticipantId,
        experimentCode: TestValues.testExperimentCode,
        promptLength: 3,
        preferenceService: mockPreferenceService,
      );

      // Assert
      expect(entries.single.study, equals('unknown'));
    });

    test('returns an empty list when there is no saved start or end time',
        () async {
      // Arrange
      stubPreferences();

      // Act
      final entries = await submitDiaryCompletionTime(
        diary: testDiary,
        study: testStudy,
        participantID: TestValues.testParticipantId,
        experimentCode: TestValues.testExperimentCode,
        promptLength: 3,
        preferenceService: mockPreferenceService,
      );

      // Assert
      expect(entries, isEmpty);
    });

    test('only returns an entry for the diary whose id has a saved start',
        () async {
      // Arrange
      stubPreferences(starts: {'2': '2024-01-01T08:00:00.000'});

      // Act
      final entries = await submitDiaryCompletionTime(
        diary: testDiary, // id: 1, not present in starts map
        study: testStudy,
        participantID: TestValues.testParticipantId,
        experimentCode: TestValues.testExperimentCode,
        promptLength: 3,
        preferenceService: mockPreferenceService,
      );

      // Assert
      expect(entries, isEmpty);
    });

    test('removes the diary entry from saved start times after building it',
        () async {
      // Arrange
      stubPreferences(starts: {
        '1': '2024-01-01T08:00:00.000',
        '2': '2024-01-02T08:00:00.000',
      });

      // Act
      await submitDiaryCompletionTime(
        diary: testDiary,
        study: testStudy,
        participantID: TestValues.testParticipantId,
        experimentCode: TestValues.testExperimentCode,
        promptLength: 3,
        preferenceService: mockPreferenceService,
      );

      // Assert
      final captured = verify(() => mockPreferenceService.setStringPreference(
          key: 'diary_starts', value: captureAny(named: 'value'))).captured;
      final savedStarts =
          jsonDecode(captured.single as String) as Map<String, dynamic>;
      expect(savedStarts.containsKey('1'), isFalse);
      expect(savedStarts.containsKey('2'), isTrue);
    });
  });
}
