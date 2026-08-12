import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/objectbox.g.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/answer.dart'
    as entities;
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/protocol_entity.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/prompt_entity.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/summary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/summary_cubit.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/experiment.dart'
    as experiment_entity;
import 'package:audio_diaries_flutter/screens/home/domain/entities/study.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/participant.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/questions_entity.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../dummy_data.dart';

// Mocks for ObjectBox and its component
class MockObjectBox extends Mock implements ObjectBox {}

class MockStore extends Mock implements Store {
  final Map<Type, Box> _boxes = {};

  void addBox<T>(Box<T> box) {
    _boxes[T] = box;
  }

  @override
  Box<T> box<T>() {
    if (_boxes.containsKey(T)) {
      return _boxes[T]! as Box<T>;
    }
    throw UnimplementedError('Box for type $T not mocked.');
  }
}

class MockDiaryBox extends Mock implements Box<Diary> {}

class MockProtocolBox extends Mock implements Box<ProtocolEntity> {}

class MockStudyBox extends Mock implements Box<Study> {}

class MockPromptBox extends Mock implements Box<Prompt> {}

class MockAnswerBox extends Mock implements Box<entities.Answer> {}

class MockParticipantBox extends Mock implements Box<Participant> {}

class MockQuestionsBox extends Mock implements Box<QuestionsEntity> {}

class MockExperimentBox extends Mock
    implements Box<experiment_entity.Experiment> {}

// Mock for Prompt Entity to control its behavior
class MockPromptEntity extends Mock implements Prompt {}

class MockAnswerEntity extends Mock implements entities.Answer {}

class MockToMany<T> extends Mock implements ToMany<T> {
  @override
  int get length => 0; // Return 0 for empty list

  T? elementAtOrNull(int index) => null; // Return null for empty list
}

class MockQuery<T> extends Mock implements Query<T> {}

class MockQueryBuilder<T> extends Mock implements QueryBuilder<T> {}

// Mock for SummaryRepository
class MockSummaryRepository extends Mock implements SummaryRepository {}

class MockDiaryRepository extends Mock implements DiaryRepository {}

void main() {
  // Test data - Create Answer with proper List<String> response
  final testAnswer = entities.Answer(
    id: 1,
    date: DateTime(2023, 1, 1),
    response: ['test response'], // Proper List<String> format
  );

  final testPromptModel1 = createTestPromptModel();

  final testDiary = createTestDiaryModel();

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Mock the platform channel for shared_preferences
    const MethodChannel('plugins.flutter.io/shared_preferences')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, dynamic>{}; // Return an empty map
      }
      return null;
    });

    registerFallbackValue(testDiary);
    registerFallbackValue(testPromptModel1);
    registerFallbackValue(Prompt.fromModel(testPromptModel1));
    registerFallbackValue(testAnswer);
  });

  group('SummaryCubit Unit Tests', () {
    late MockSummaryRepository mockSummaryRepository;

    setUp(() {
      mockSummaryRepository = MockSummaryRepository();

      // Mock shared preferences
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state is SummaryInitial', () {
      // Use mock repository even for initial state test
      final cubit = SummaryCubit(summaryRepository: mockSummaryRepository);
      expect(cubit.state, const SummaryInitial());
    });

    group('loadSummary', () {
      blocTest<SummaryCubit, SummaryState>(
        'emits [SummaryLoading, SummaryLoaded] when loadSummary succeeds',
        setUp: () {
          // Mock successful loadSummary
          when(() => mockSummaryRepository.loadSummary(any()))
              .thenAnswer((_) async => testDiary);
        },
        build: () => SummaryCubit(summaryRepository: mockSummaryRepository),
        act: (cubit) => cubit.loadSummary(testDiary),
        expect: () => [
          const SummaryLoading(),
          isA<SummaryLoaded>(),
        ],
        verify: (cubit) {
          verify(() => mockSummaryRepository.loadSummary(testDiary)).called(1);
        },
      );

      blocTest<SummaryCubit, SummaryState>(
        'emits [SummaryLoading] and handles exception gracefully',
        setUp: () {
          // Mock exception
          when(() => mockSummaryRepository.loadSummary(any()))
              .thenThrow(Exception('Test error'));
        },
        build: () => SummaryCubit(summaryRepository: mockSummaryRepository),
        act: (cubit) => cubit.loadSummary(testDiary),
        expect: () => [
          const SummaryLoading(),
          // Note: The cubit catches exceptions and logs them, but doesn't emit error state
        ],
      );
    });

    group('saveResponse', () {
      blocTest<SummaryCubit, SummaryState>(
        'calls saveResponse and then loadSummary',
        setUp: () {
          // Mock saveResponse - it returns void
          when(() => mockSummaryRepository.saveResponse(any(), any(), any()))
              .thenReturn(null);

          // Mock the subsequent loadSummary call
          when(() => mockSummaryRepository.loadSummary(any()))
              .thenAnswer((_) async => testDiary);
        },
        build: () => SummaryCubit(summaryRepository: mockSummaryRepository),
        act: (cubit) => cubit.saveResponse(
            testDiary, testPromptModel1, 'test path', 'text'),
        expect: () => [
          const SummaryLoading(),
          isA<SummaryLoaded>(),
        ],
        verify: (cubit) {
          verify(() => mockSummaryRepository.saveResponse(
              testPromptModel1, 'test path', 'text')).called(1);
          verify(() => mockSummaryRepository.loadSummary(testDiary)).called(1);
        },
      );

      blocTest<SummaryCubit, SummaryState>(
        'handles saveResponse exception gracefully',
        setUp: () {
          // Mock saveResponse to throw exception
          when(() => mockSummaryRepository.saveResponse(any(), any(), any()))
              .thenThrow(Exception('Save error'));

          // Mock the subsequent loadSummary call (called in finally block)
          when(() => mockSummaryRepository.loadSummary(any()))
              .thenAnswer((_) async => testDiary);
        },
        build: () => SummaryCubit(summaryRepository: mockSummaryRepository),
        act: (cubit) => cubit.saveResponse(
            testDiary, testPromptModel1, 'test path', 'text'),
        expect: () => [
          const SummaryLoading(),
          isA<SummaryLoaded>(),
        ],
        verify: (cubit) {
          // Verify loadSummary is still called in finally block
          verify(() => mockSummaryRepository.loadSummary(testDiary)).called(1);
        },
      );
    });

    group('removeResponse', () {
      blocTest<SummaryCubit, SummaryState>(
        'calls removeResponse and then loadSummary when successful',
        setUp: () {
          // Mock successful removeResponse
          when(() => mockSummaryRepository.removeResponse(any(), any()))
              .thenAnswer((_) async => true);

          // Mock the subsequent loadSummary call
          when(() => mockSummaryRepository.loadSummary(any()))
              .thenAnswer((_) async => testDiary);
        },
        build: () => SummaryCubit(summaryRepository: mockSummaryRepository),
        act: (cubit) =>
            cubit.removeResponse(testDiary, testPromptModel1, 'test path'),
        expect: () => [
          const SummaryLoading(),
          isA<SummaryLoaded>(),
        ],
        verify: (cubit) {
          verify(() => mockSummaryRepository.removeResponse(
              testPromptModel1, 'test path')).called(1);
          verify(() => mockSummaryRepository.loadSummary(testDiary)).called(1);
        },
      );

      blocTest<SummaryCubit, SummaryState>(
        'does not call loadSummary when removeResponse returns false',
        setUp: () {
          // Mock failed removeResponse
          when(() => mockSummaryRepository.removeResponse(any(), any()))
              .thenAnswer((_) async => false);
        },
        build: () => SummaryCubit(summaryRepository: mockSummaryRepository),
        act: (cubit) =>
            cubit.removeResponse(testDiary, testPromptModel1, 'test path'),
        expect: () => const <SummaryState>[],
        verify: (cubit) {
          verify(() => mockSummaryRepository.removeResponse(
              testPromptModel1, 'test path')).called(1);
          // loadSummary should not be called when removeResponse returns false
          verifyNever(() => mockSummaryRepository.loadSummary(any()));
        },
      );
    });

    group('submitDiary', () {
      blocTest<SummaryCubit, SummaryState>(
        'emits [SubmitLoading, SummarySubmitted] when submission succeeds',
        setUp: () {
          // Mock successful submission
          when(() => mockSummaryRepository.submitDiary(any()))
              .thenAnswer((_) async => true);
          when(() => mockSummaryRepository.calculateEarnedIncentives(any()))
              .thenAnswer((_) async {});
        },
        build: () => SummaryCubit(summaryRepository: mockSummaryRepository),
        act: (cubit) => cubit.submitDiary(testDiary),
        expect: () => [
          const SubmitLoading(),
          const SummarySubmitted(),
        ],
        verify: (cubit) {
          verify(() => mockSummaryRepository.submitDiary(testDiary)).called(1);
          verify(() =>
                  mockSummaryRepository.calculateEarnedIncentives(testDiary))
              .called(1);
        },
      );

      blocTest<SummaryCubit, SummaryState>(
        'emits [SubmitLoading, SubmitError] when submission fails',
        setUp: () {
          // Mock failed submission
          when(() => mockSummaryRepository.submitDiary(any()))
              .thenAnswer((_) async => false);
        },
        build: () => SummaryCubit(summaryRepository: mockSummaryRepository),
        act: (cubit) => cubit.submitDiary(testDiary),
        expect: () => [
          const SubmitLoading(),
          const SubmitError(),
        ],
        verify: (cubit) {
          verify(() => mockSummaryRepository.submitDiary(testDiary)).called(1);
          verifyNever(
              () => mockSummaryRepository.calculateEarnedIncentives(any()));
        },
      );

      blocTest<SummaryCubit, SummaryState>(
        'emits [SubmitLoading, SubmitError] when exception occurs',
        setUp: () {
          // Mock exception during submission
          when(() => mockSummaryRepository.submitDiary(any()))
              .thenThrow(Exception('Network error'));
        },
        build: () => SummaryCubit(summaryRepository: mockSummaryRepository),
        act: (cubit) => cubit.submitDiary(testDiary),
        expect: () => [
          const SubmitLoading(),
          const SubmitError(),
        ],
      );
    });

    group('partial answer uploads', () {
      test('marks an acknowledged answer as successful', () async {
        final answeredPrompt = createTestPromptModel(answer: testAnswer);
        final answeredDiary = createTestDiaryModel(prompts: [answeredPrompt]);
        when(() => mockSummaryRepository.loadSummary(answeredDiary))
            .thenAnswer((_) async => answeredDiary);
        when(() => mockSummaryRepository.submitPrompt(
            answeredDiary, answeredPrompt)).thenAnswer((_) async => true);

        final cubit = SummaryCubit(summaryRepository: mockSummaryRepository);
        await cubit.loadSummary(answeredDiary, uploadAnswers: true);
        await cubit.uploadPendingAnswers();

        final state = cubit.state as SummaryLoaded;
        expect(state.submissionStatuses[answeredPrompt.id],
            AnswerSubmissionStatus.successful);
        verify(() => mockSummaryRepository.submitPrompt(
            answeredDiary, answeredPrompt)).called(1);
        await cubit.close();
      });

      test('marks a rejected answer as failed', () async {
        final answeredPrompt = createTestPromptModel(answer: testAnswer);
        final answeredDiary = createTestDiaryModel(prompts: [answeredPrompt]);
        when(() => mockSummaryRepository.loadSummary(answeredDiary))
            .thenAnswer((_) async => answeredDiary);
        when(() => mockSummaryRepository.submitPrompt(
            answeredDiary, answeredPrompt)).thenAnswer((_) async => false);

        final cubit = SummaryCubit(summaryRepository: mockSummaryRepository);
        await cubit.loadSummary(answeredDiary, uploadAnswers: true);
        await cubit.uploadPendingAnswers();

        final state = cubit.state as SummaryLoaded;
        expect(state.submissionStatuses[answeredPrompt.id],
            AnswerSubmissionStatus.failed);
        await cubit.close();
      });
    });

    group('updateDiaryCompletion', () {
      late MockDiaryRepository mockDiaryRepository;

      setUp(() {
        mockDiaryRepository = MockDiaryRepository();
        when(() => mockSummaryRepository.diaryRepository)
            .thenReturn(mockDiaryRepository);
        when(() => mockDiaryRepository.updateDiary(any()))
            .thenAnswer((_) async {});
      });

      test('saves diary with completions added and submissions preserved',
          () async {
        final submissions = [DateTime(2024, 1, 1, 10)];
        final activeDays = [1, 2, 3];
        final diary = createTestDiaryModel(
          currentEntry: 0,
          submissions: submissions,
          activeDays: activeDays,
          completions: null,
        );

        final cubit = SummaryCubit(summaryRepository: mockSummaryRepository);
        await cubit.updateDiaryCompletion(diary);

        final captured = verify(() => mockDiaryRepository.updateDiary(captureAny()))
            .captured
            .single as DiaryModel;

        expect(captured.submissions, equals(submissions),
            reason: 'submissions must be preserved across the copyWith');
        expect(captured.activeDays, equals(activeDays),
            reason: 'activeDays must be preserved across the copyWith');
        expect(captured.completions, hasLength(1),
            reason: 'one completion timestamp should be added');
      });

      test('does not save when completion for current entry already exists', () async {
        final existing = DateTime(2024, 1, 1, 9);
        final diary = createTestDiaryModel(
          currentEntry: 0,
          completions: [existing],
        );

        final cubit = SummaryCubit(summaryRepository: mockSummaryRepository);
        await cubit.updateDiaryCompletion(diary);

        verifyNever(() => mockDiaryRepository.updateDiary(any()));
      });
    });

    group('checkForLocationPermission', () {
      test('returns null when location is not an extra permission', () async {
        SharedPreferences.setMockInitialValues({
          'extra_permissions': ['camera']
        });
        final cubit = SummaryCubit(summaryRepository: mockSummaryRepository);
        final result = await cubit.checkForLocationPermission();
        expect(result, isNull);
      });

      test(
        'throws MissingPluginException when location permission is checked without full environment',
        () async {
          SharedPreferences.setMockInitialValues({
            'extra_permissions': ['location']
          });
          final cubit = SummaryCubit(summaryRepository: mockSummaryRepository);
          // The l.Location() constructor will try to access a method channel
          // which is not available in a pure unit test environment, throwing an exception.
          expect(
            () => cubit.checkForLocationPermission(),
            throwsA(isA<MissingPluginException>()),
          );
        },
      );
    });
  });
}
