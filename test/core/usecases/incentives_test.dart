import 'dart:convert';

import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:audio_diaries_flutter/core/usecases/incentives.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import '../../dummy_data.dart';

class MockSetupRepository extends Mock implements SetupRepository {}

class MockDiaryRepository extends Mock implements DiaryRepository {}

class MockPreferenceService extends Mock implements PreferenceService {}

class MockSecureSave extends Mock implements SecureSave {}

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockSetupRepository mockSetupRepository;
  late MockDiaryRepository mockDiaryRepository;
  late MockPreferenceService mockPreferenceService;
  late MockSecureSave mockSecureSave;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse(TestValues.testUrl));
  });

  setUp(() {
    mockSetupRepository = MockSetupRepository();
    mockDiaryRepository = MockDiaryRepository();
    mockPreferenceService = MockPreferenceService();
    mockSecureSave = MockSecureSave();
    mockHttpClient = MockHttpClient();

    when(() => mockSetupRepository.getExperiment())
        .thenReturn(createTestExperimentModel());
    when(() => mockSecureSave.read())
        .thenAnswer((_) async => createTestCredentials());
    when(() => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('Success', 200));
    when(() => mockPreferenceService.setBoolPreference(
        key: any(named: 'key'),
        value: any(named: 'value'))).thenAnswer((_) async => true);
  });

  Future<bool> callWithMocks({required int studyID}) {
    return calculateEarnedIncentivesForAWS(
      participantID: TestValues.testParticipantId,
      studyID: studyID,
      setupRepository: mockSetupRepository,
      diaryRepository: mockDiaryRepository,
      preferenceService: mockPreferenceService,
      secureSave: mockSecureSave,
      client: mockHttpClient,
    );
  }

  Future<List<Map<String, dynamic>>> capturedEntries() async {
    final captured = verify(() => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: captureAny(named: 'body'),
        )).captured;
    final body = captured.single as String;
    return (json.decode(body) as List).cast<Map<String, dynamic>>();
  }

  group('calculateEarnedIncentivesForAWS', () {
    test(
        'submits Incentives, StudyIncentive and BonusEarned entries when the threshold is newly met',
        () async {
      // Arrange
      final study = createTestStudyModel(
          id: 1, studyId: 1, name: 'Study One', incentive: createTestIncentive(
        amount: 10,
        bonus: 5,
        currency: '\$',
        threshold: 80,
      ));
      final diaries = [
        createTestDiaryModel(id: 1, studyID: 1, status: DiaryStatus.submitted),
        createTestDiaryModel(id: 2, studyID: 1, status: DiaryStatus.submitted),
      ];

      when(() => mockDiaryRepository.getAllDiariesWithMultipleEntries())
          .thenReturn(diaries);
      when(() => mockDiaryRepository.getAllStudies()).thenReturn([study]);
      when(() => mockPreferenceService.getBoolPreference(
          key: 'bonus_given_study_1')).thenAnswer((_) async => false);

      // Act
      final result = await callWithMocks(studyID: 1);

      // Assert
      expect(result, isTrue);
      final entries = await capturedEntries();
      expect(entries.map((e) => e['QuestionsType']),
          containsAll(['Incentives', 'StudyIncentive', 'BonusEarned']));

      final incentives =
          entries.firstWhere((e) => e['QuestionsType'] == 'Incentives');
      // Both diaries submitted (2 * 10) + bonus (5) = 25
      expect(incentives['Response'], equals(formatMoney(25, currency: '\$')));

      final studyIncentive =
          entries.firstWhere((e) => e['QuestionsType'] == 'StudyIncentive');
      expect(studyIncentive['Study'], equals('Study One'));
      // 2 completed diaries * amount 10 = 20
      expect(
          studyIncentive['Response'], equals(formatMoney(20, currency: '\$')));

      final bonus =
          entries.firstWhere((e) => e['QuestionsType'] == 'BonusEarned');
      expect(bonus['Study'], equals('Study One'));
      expect(bonus['Response'], equals(formatMoney(5, currency: '\$')));

      verify(() => mockPreferenceService.setBoolPreference(
          key: 'bonus_given_study_1', value: true)).called(1);
    });

    test('does not resubmit the bonus once it has already been given',
        () async {
      // Arrange
      final study = createTestStudyModel(id: 1, studyId: 1, name: 'Study One');
      final diaries = [
        createTestDiaryModel(id: 1, studyID: 1, status: DiaryStatus.submitted),
      ];

      when(() => mockDiaryRepository.getAllDiariesWithMultipleEntries())
          .thenReturn(diaries);
      when(() => mockDiaryRepository.getAllStudies()).thenReturn([study]);
      when(() => mockPreferenceService.getBoolPreference(
          key: 'bonus_given_study_1')).thenAnswer((_) async => true);

      // Act
      final result = await callWithMocks(studyID: 1);

      // Assert
      expect(result, isTrue);
      final entries = await capturedEntries();
      expect(entries.map((e) => e['QuestionsType']),
          containsAll(['Incentives', 'StudyIncentive']));
      expect(entries.any((e) => e['QuestionsType'] == 'BonusEarned'), isFalse);

      verifyNever(() => mockPreferenceService.setBoolPreference(
          key: any(named: 'key'), value: any(named: 'value')));
    });

    test(
        'only submits the overall Incentives entry when studyID matches no known study',
        () async {
      // Arrange
      final study = createTestStudyModel(id: 1, studyId: 1);
      final diaries = [
        createTestDiaryModel(id: 1, studyID: 1, status: DiaryStatus.submitted),
      ];

      when(() => mockDiaryRepository.getAllDiariesWithMultipleEntries())
          .thenReturn(diaries);
      when(() => mockDiaryRepository.getAllStudies()).thenReturn([study]);

      // Act
      final result = await callWithMocks(studyID: 999);

      // Assert
      expect(result, isTrue);
      final entries = await capturedEntries();
      expect(entries.length, equals(1));
      expect(entries.single['QuestionsType'], equals('Incentives'));

      verifyNever(() => mockPreferenceService.getBoolPreference(
          key: any(named: 'key')));
    });

    test('handles a study with no diaries without crashing', () async {
      // Arrange
      final studyWithDiaries = createTestStudyModel(id: 1, studyId: 1);
      final emptyStudy =
          createTestStudyModel(id: 2, studyId: 2, name: 'Empty Study');
      final diaries = [
        createTestDiaryModel(id: 1, studyID: 1, status: DiaryStatus.submitted),
      ];

      when(() => mockDiaryRepository.getAllDiariesWithMultipleEntries())
          .thenReturn(diaries);
      when(() => mockDiaryRepository.getAllStudies())
          .thenReturn([studyWithDiaries, emptyStudy]);
      when(() => mockPreferenceService.getBoolPreference(
          key: 'bonus_given_study_2')).thenAnswer((_) async => false);

      // Act
      final result = await callWithMocks(studyID: 2);

      // Assert
      expect(result, isTrue);
      final entries = await capturedEntries();
      final studyIncentive =
          entries.firstWhere((e) => e['QuestionsType'] == 'StudyIncentive');
      expect(studyIncentive['Response'], equals(formatMoney(0, currency: '\$')));
      expect(entries.any((e) => e['QuestionsType'] == 'BonusEarned'), isFalse);
    });

    test('does not persist the bonus flag when the upload fails', () async {
      // Arrange
      final study = createTestStudyModel(id: 1, studyId: 1);
      final diaries = [
        createTestDiaryModel(id: 1, studyID: 1, status: DiaryStatus.submitted),
      ];

      when(() => mockDiaryRepository.getAllDiariesWithMultipleEntries())
          .thenReturn(diaries);
      when(() => mockDiaryRepository.getAllStudies()).thenReturn([study]);
      when(() => mockPreferenceService.getBoolPreference(
          key: 'bonus_given_study_1')).thenAnswer((_) async => false);
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Error', 400));

      // Act
      final result = await callWithMocks(studyID: 1);

      // Assert
      expect(result, isFalse);
      verifyNever(() => mockPreferenceService.setBoolPreference(
          key: any(named: 'key'), value: any(named: 'value')));
    });
  });
}
