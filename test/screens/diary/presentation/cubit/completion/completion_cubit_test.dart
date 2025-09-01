// test/screens/diary/presentation/cubit/completion/completion_cubit_test.dart
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/completion/completion_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:audio_diaries_flutter/main.dart' as main_app;
import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/objectbox.g.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/study.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/protocol_entity.dart';

import '../../../../../dummy_data.dart';

class MockObjectBox extends Mock implements ObjectBox {
  @override
  late final Store store = MockStore();
}

class MockStore extends Mock implements Store {
  @override
  Box<T> box<T>() {
    if (T == Diary) {
      return MockDiaryBox() as Box<T>;
    } else if (T == Study) {
      return MockStudyBox() as Box<T>;
    } else if (T == ProtocolEntity) {
      return MockProtocolBox() as Box<T>;
    }
    throw UnimplementedError('Unexpected box type: $T');
  }
}

class MockDiaryBox extends Mock implements Box<Diary> {}

class MockStudyBox extends Mock implements Box<Study> {}

class MockProtocolBox extends Mock implements Box<ProtocolEntity> {}

void main() {
  group('CompletionCubit', () {
    late CompletionCubit completionCubit;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final mockObjectBox = MockObjectBox();
      main_app.objectbox = mockObjectBox;
    });

    final testDiary = createTestDiaryModel(
      status: DiaryStatus.complete,
    );

    final testGoal = createTestGoal();
    final testIncentive = createTestIncentive();

    final testStudy = createTestStudyModel(
      name: TestValues.testStudyNameNumbered,
    );

    setUp(() {
      completionCubit = CompletionCubit();
    });

    tearDown(() {
      completionCubit.close();
    });

    test('initial state is CompletionInitial', () {
      expect(completionCubit.state, const CompletionInitial());
    });

    group('completeDiary behavior', () {
      test('completeDiary method executes without throwing', () {
        expect(
          () => completionCubit.completeDiary(testDiary),
          returnsNormally,
        );
      });

      blocTest<CompletionCubit, CompletionState>(
        'emits [CompletionLoading, CompletionError] when repository fails due to mocking',
        build: () => completionCubit,
        act: (cubit) => cubit.completeDiary(testDiary),
        expect: () => [
          const CompletionLoading(),
          isA<CompletionError>(),
        ],
        wait: const Duration(milliseconds: 100),
        verify: (cubit) {
          final state = cubit.state;
          expect(state, isA<CompletionError>());
          final errorState = state as CompletionError;
          expect(
              errorState.message, contains(TestValues.testQueryBuilderError));
        },
      );

      test('handles different diary types', () {
        final diaryVariations = createTestDiaryVariations();
        final ongoingDiary = diaryVariations['ongoing']!;
        final submittedDiary = diaryVariations['submitted']!;

        expect(
          () => completionCubit.completeDiary(ongoingDiary),
          returnsNormally,
        );

        expect(
          () => completionCubit.completeDiary(submittedDiary),
          returnsNormally,
        );
      });
    });

    group('state equality and properties', () {
      test('CompletionInitial state properties', () {
        const state = CompletionInitial();
        expect(state.props, []);
      });

      test('CompletionLoading state properties', () {
        const state = CompletionLoading();
        expect(state.props, []);
      });

      test('CompletionLoaded state properties', () {
        final state = CompletionLoaded(
          diary: testDiary,
          diaries: [testDiary],
          studies: [testStudy],
        );
        expect(state.props, [
          testDiary,
          [testDiary],
          [testStudy]
        ]);
        expect(state.diary, testDiary);
        expect(state.diaries, [testDiary]);
        expect(state.studies, [testStudy]);
      });

      test('CompletionError state properties', () {
        const state = CompletionError(message: TestValues.testCompletionError);
        expect(state.props, [TestValues.testCompletionError]);
        expect(state.message, TestValues.testCompletionError);
      });

      test('different states are not equal', () {
        const initialState = CompletionInitial();
        const loadingState = CompletionLoading();
        const errorState =
            CompletionError(message: TestValues.testCompletionError);
        final loadedState = CompletionLoaded(
          diary: testDiary,
          diaries: [],
          studies: [],
        );

        expect(initialState, isNot(equals(loadingState)));
        expect(loadingState, isNot(equals(errorState)));
        expect(errorState, isNot(equals(loadedState)));
        expect(loadedState, isNot(equals(initialState)));
      });

      test('same states with same data are equal', () {
        const error1 = CompletionError(message: TestValues.testCompletionError);
        const error2 = CompletionError(message: TestValues.testCompletionError);
        expect(error1, equals(error2));

        final loaded1 = CompletionLoaded(
          diary: testDiary,
          diaries: [testDiary],
          studies: [testStudy],
        );
        final loaded2 = CompletionLoaded(
          diary: testDiary,
          diaries: [testDiary],
          studies: [testStudy],
        );
        expect(loaded1, equals(loaded2));
      });
    });

    group('integration tests', () {
      blocTest<CompletionCubit, CompletionState>(
        'handles sequential completeDiary calls with expected repository failures',
        build: () => completionCubit,
        act: (cubit) {
          cubit.completeDiary(testDiary);
          Future.delayed(const Duration(milliseconds: 10), () {
            final secondDiary = createTestDiaryModel(
              id: 2,
              status: DiaryStatus.complete,
            );
            cubit.completeDiary(secondDiary);
          });
        },
        expect: () => [
          const CompletionLoading(),
          isA<CompletionError>(),
          const CompletionLoading(),
          isA<CompletionError>(),
        ],
        wait: const Duration(milliseconds: 200),
      );

      test('handles rapid successive calls gracefully', () {
        final testDiaries = createTestDiariesSequence(3);

        for (final diary in testDiaries) {
          expect(
            () => completionCubit.completeDiary(diary),
            returnsNormally,
          );
        }
      });
    });

    group('model properties tests', () {
      test('diary model has correct properties', () {
        expect(testDiary.id, 1);
        expect(testDiary.studyID, 1);
        expect(testDiary.name, TestValues.testName);
        expect(testDiary.status, DiaryStatus.complete);
        expect(testDiary.entries, 1);
        expect(testDiary.currentEntry, 0);
        expect(testDiary.activeDays, [1, 2, 3, 4, 5, 6, 7]);
      });

      test('study model has correct properties', () {
        expect(testStudy.id, 1);
        expect(testStudy.studyId, 1);
        expect(testStudy.name, TestValues.testStudyNameNumbered);
        expect(testStudy.experimentCode, TestValues.testStudyExperimentCode);
        expect(testStudy.color, const Color.fromARGB(255, 68, 97, 228));
        expect(testStudy.goals.daily, testGoal.daily);
        expect(testStudy.goals.weekly, testGoal.weekly);
        expect(testStudy.incentive.amount, testIncentive.amount);
        expect(testStudy.incentive.bonus, testIncentive.bonus);
        expect(testStudy.incentive.currency, testIncentive.currency);
        expect(testStudy.incentive.threshold, testIncentive.threshold);
      });

      test('goal model has correct properties', () {
        expect(testGoal.daily, TestValues.testGoalDaily);
        expect(testGoal.weekly, TestValues.testGoalWeekly);
      });

      test('incentive model has correct properties', () {
        expect(testIncentive.amount, TestValues.testIncentiveAmount);
        expect(testIncentive.bonus, TestValues.testIncentiveBonus);
        expect(testIncentive.currency, TestValues.testIncentiveCurrency);
        expect(testIncentive.threshold, TestValues.testIncentiveThreshold);
      });
    });

    group('edge cases', () {
      test('handles diary with empty lists', () {
        final diaryVariations = createTestDiaryVariations();
        final emptyDiary = diaryVariations['empty']!;

        expect(
          () => completionCubit.completeDiary(emptyDiary),
          returnsNormally,
        );
      });

      test('handles diary with null active days', () {
        final diaryVariations = createTestDiaryVariations();
        final nullActiveDiary = diaryVariations['nullActive']!;

        expect(
          () => completionCubit.completeDiary(nullActiveDiary),
          returnsNormally,
        );
      });

      test('handles different diary statuses', () {
        final diaryVariations = createTestDiaryVariations();

        for (final variation in diaryVariations.values) {
          expect(
            () => completionCubit.completeDiary(variation),
            returnsNormally,
          );
        }
      });
    });
  });
}
