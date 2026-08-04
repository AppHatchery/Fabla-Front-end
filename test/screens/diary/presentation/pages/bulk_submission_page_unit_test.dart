import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/main.dart' as app;
import 'package:audio_diaries_flutter/objectbox.g.dart';
import 'package:audio_diaries_flutter/screens/diary/data/bulk_submission.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/summary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/bulk_submission/bulk_submission_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:objectbox/objectbox.dart';

import '../../../../core/usecases/location_test.dart';
import '../../../../dummy_data.dart';
import '../../../../mock_classes.mocks.dart';

class MockObjectBox extends Mock implements ObjectBox {
  //mock class from mock_classes.dart
  @override
  late final Store store = MockStore();
}

class MockSummaryRepository extends Mock implements SummaryRepository {}

void main() {
  late MockSummaryRepository mockSummaryRepository;
  late MockPreferenceService mockPreferenceService;
  late BulkSubmissionCubit bulkSubmissionCubit;

  // Use centralized helpers
  List<DiarySubmission> createTestSubmissions(
    int count, {
    SubmissionStatus? status,
  }) {
    final study = createTestStudyModel(); // study data from dummy data file
    return List.generate(count, (index) {
      final diary = createTestDiaryModel(
        //diary model from dummy data file
        id: index + 1,
        studyID: study.id,
        name: '${TestValues.testDiaryOngoing} ${index + 1}',
      );
      return DiarySubmission(
        diary: diary,
        study: study,
        status: status ?? SubmissionStatus.pending,
      );
    });
  }

  setUpAll(() {
    app.objectbox = MockObjectBox();
    registerFallbackValue(createTestDiaryModel());
  });

  setUp(() {
    mockSummaryRepository = MockSummaryRepository();
    mockPreferenceService = MockPreferenceService();
    bulkSubmissionCubit = BulkSubmissionCubit(
        summaryRepository: mockSummaryRepository,
        preferenceService: mockPreferenceService);
  });

  tearDown(() {
    bulkSubmissionCubit.close();
  });

  group('constructor', () {
    test('initial state is BulkSubmissionInitial', () {
      expect(bulkSubmissionCubit.state, isA<BulkSubmissionInitial>());
    });

    test('uses provided summaryRepository', () {
      final customRepo = MockSummaryRepository();
      final cubit = BulkSubmissionCubit(summaryRepository: customRepo);
      expect(cubit.state, isA<BulkSubmissionInitial>());
      cubit.close();
    });
  });

  group('startBulkSubmission', () {
    blocTest<BulkSubmissionCubit, BulkSubmissionState>(
      'emits success when all submissions succeed',
      build: () => bulkSubmissionCubit,
      setUp: () {
        when(() => mockSummaryRepository.submitDiary(any()))
            .thenAnswer((_) async => true);
        when(() => mockPreferenceService.setBoolPreference(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async => true);
      },
      act: (cubit) {
        final submissions = createTestSubmissions(2);
        cubit.startBulkSubmission(submissions);
      },
      expect: () => [
        isA<BulkSubmissionInProgress>()
            .having((state) => state.counter, 'initial counter', 0),
        isA<BulkSubmissionInProgress>()
            .having((state) => state.counter, 'counter after first', 1),
        isA<BulkSubmissionInProgress>()
            .having((state) => state.counter, 'counter after second', 2),
        isA<BulkSubmissionSuccess>(),
      ],
      wait: const Duration(seconds: 2),
    );

    blocTest<BulkSubmissionCubit, BulkSubmissionState>(
      'emits failed when some submissions fail',
      build: () => bulkSubmissionCubit,
      setUp: () {
        when(() => mockSummaryRepository.submitDiary(any()))
            .thenAnswer((_) async => false);
        when(() => mockPreferenceService.setBoolPreference(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async => false);
      },
      act: (cubit) {
        final submissions = createTestSubmissions(2);
        cubit.startBulkSubmission(submissions);
      },
      expect: () => [
        isA<BulkSubmissionInProgress>()
            .having((state) => state.counter, 'initial counter', 0),
        isA<BulkSubmissionFailed>()
            .having((state) => state.failedCount, 'failed count', 2)
            .having((state) => state.diaries.length, 'diaries length', 2),
      ],
      wait: const Duration(seconds: 2),
    );

    blocTest<BulkSubmissionCubit, BulkSubmissionState>(
      'emits failed when submissions return null (network issue)',
      build: () => bulkSubmissionCubit,
      setUp: () {
        when(() => mockSummaryRepository.submitDiary(any()))
            .thenAnswer((_) async => null);
        when(() => mockPreferenceService.setBoolPreference(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async => false);
      },
      act: (cubit) {
        final submissions = createTestSubmissions(1);
        cubit.startBulkSubmission(submissions);
      },
      expect: () => [
        isA<BulkSubmissionInProgress>(),
        isA<BulkSubmissionFailed>()
            .having((state) => state.failedCount, 'failed count', 1),
      ],
      wait: const Duration(seconds: 2),
    );

    blocTest<BulkSubmissionCubit, BulkSubmissionState>(
      'emits mixed results correctly',
      build: () => bulkSubmissionCubit,
      setUp: () {
        var callCount = 0;
        when(() => mockSummaryRepository.submitDiary(any()))
            .thenAnswer((_) async {
          callCount++;
          return callCount == 1; // First succeeds, second fails
        });
      },
      act: (cubit) {
        final submissions = createTestSubmissions(2);
        cubit.startBulkSubmission(submissions);
      },
      expect: () => [
        isA<BulkSubmissionInProgress>()
            .having((state) => state.counter, 'initial counter', 0),
        isA<BulkSubmissionInProgress>()
            .having((state) => state.counter, 'counter after first success', 1),
        isA<BulkSubmissionFailed>()
            .having((state) => state.failedCount, 'failed count', 1),
      ],
      wait: const Duration(seconds: 2),
    );

    blocTest<BulkSubmissionCubit, BulkSubmissionState>(
      'handles empty submissions list',
      build: () => bulkSubmissionCubit,
      setUp: () {
        when(() => mockPreferenceService.setBoolPreference(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async => false);
      },
      act: (cubit) {
        cubit.startBulkSubmission([]);
      },
      expect: () => [
        isA<BulkSubmissionInProgress>()
            .having((state) => state.diaries, 'empty diaries', isEmpty),
        isA<BulkSubmissionSuccess>(),
      ],
      wait: const Duration(seconds: 1),
    );

    blocTest<BulkSubmissionCubit, BulkSubmissionState>(
      'emits error when repository throws exception',
      build: () => bulkSubmissionCubit,
      setUp: () {
        when(() => mockSummaryRepository.submitDiary(any()))
            .thenThrow(Exception('Network error'));
      },
      act: (cubit) {
        final submissions = createTestSubmissions(1);
        cubit.startBulkSubmission(submissions);
      },
      expect: () => [
        isA<BulkSubmissionInProgress>(),
        isA<BulkSubmissionError>().having((state) => state.message,
            'error message', contains('Network error')),
      ],
      wait: const Duration(seconds: 2),
    );
  });

  group('retryFailedSubmissions', () {
    blocTest<BulkSubmissionCubit, BulkSubmissionState>(
      'resets failed submissions to pending and retries',
      build: () => bulkSubmissionCubit,
      setUp: () {
        when(() => mockSummaryRepository.submitDiary(any()))
            .thenAnswer((_) async => true);
        when(() => mockPreferenceService.setBoolPreference(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async => true);
      },
      act: (cubit) {
        final submissions =
            createTestSubmissions(2, status: SubmissionStatus.failed);
        cubit.retryFailedSubmissions(submissions);
      },
      expect: () => [
        isA<BulkSubmissionInProgress>()
            .having((state) => state.counter, 'initial counter', 0),
        isA<BulkSubmissionInProgress>()
            .having((state) => state.counter, 'counter after first', 1),
        isA<BulkSubmissionInProgress>()
            .having((state) => state.counter, 'counter after second', 2),
        isA<BulkSubmissionSuccess>(),
      ],
      wait: const Duration(seconds: 2),
    );

    blocTest<BulkSubmissionCubit, BulkSubmissionState>(
      'preserves successful submissions and only retries failed ones',
      build: () => bulkSubmissionCubit,
      setUp: () {
        when(() => mockSummaryRepository.submitDiary(any()))
            .thenAnswer((_) async => true);
        when(() => mockPreferenceService.setBoolPreference(
              key: any(named: 'key'),
              value: any(named: 'value'),
            )).thenAnswer((_) async => true);
      },
      act: (cubit) {
        final submissions = [
          createTestSubmissions(1, status: SubmissionStatus.successful)[0],
          createTestSubmissions(1, status: SubmissionStatus.failed)[0],
        ];
        cubit.retryFailedSubmissions(submissions);
      },
      expect: () => [
        isA<BulkSubmissionInProgress>()
            .having((state) => state.counter, 'initial counter', 0),
        isA<BulkSubmissionInProgress>()
            .having((state) => state.counter, 'counter after retry', 2),
        isA<BulkSubmissionSuccess>(),
      ],
      wait: const Duration(seconds: 2),
    );

    blocTest<BulkSubmissionCubit, BulkSubmissionState>(
      'handles retry failure correctly',
      build: () => bulkSubmissionCubit,
      setUp: () {
        when(() => mockSummaryRepository.submitDiary(any()))
            .thenAnswer((_) async => false);
      },
      act: (cubit) {
        final submissions =
            createTestSubmissions(1, status: SubmissionStatus.failed);
        cubit.retryFailedSubmissions(submissions);
      },
      expect: () => [
        isA<BulkSubmissionInProgress>(),
        isA<BulkSubmissionFailed>()
            .having((state) => state.failedCount, 'failed count', 1),
      ],
      wait: const Duration(seconds: 2),
    );
  });

  group('edge cases', () {
    test('submission list is copied and modifications do not affect original',
        () async {
      when(() => mockSummaryRepository.submitDiary(any()))
          .thenAnswer((_) async => true);
      when(() => mockPreferenceService.setBoolPreference(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async => true);

      final originalSubmissions = createTestSubmissions(1);
      final originalStatus = originalSubmissions[0].status;

      bulkSubmissionCubit.startBulkSubmission(originalSubmissions);
      await Future.delayed(const Duration(seconds: 1));

      // Original list should be unchanged
      expect(originalSubmissions[0].status, equals(originalStatus));
    });
  });

  group('state equality', () {
    test('BulkSubmissionInProgress states are equal with same data', () {
      final submissions = createTestSubmissions(2);
      final state1 = BulkSubmissionInProgress(submissions, counter: 1);
      final state2 = BulkSubmissionInProgress(submissions, counter: 1);

      expect(state1, equals(state2));
      expect(state1.props, equals(state2.props));
    });

    test('BulkSubmissionFailed states are equal with same data', () {
      final submissions = createTestSubmissions(2);
      final state1 = BulkSubmissionFailed(submissions, 1);
      final state2 = BulkSubmissionFailed(submissions, 1);

      expect(state1, equals(state2));
      expect(state1.props, equals(state2.props));
    });

    test('BulkSubmissionError states are equal with same message', () {
      final state1 = BulkSubmissionError('Error message');
      final state2 = BulkSubmissionError('Error message');

      expect(state1, equals(state2));
      expect(state1.props, equals(state2.props));
    });
  });
}
