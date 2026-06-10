import 'package:audio_diaries_flutter/core/usecases/experiment_manager.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/hub/presentation/cubit/hub_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes using mocktail
class MockExperimentManager extends Mock implements ExperimentManager {}

class MockDiaryRepository extends Mock implements DiaryRepository {}

class MockDiaryModel extends Mock implements DiaryModel {}

void main() {
  // getDailyDiaries takes a DateTime; mocktail's any() needs a fallback for it.
  setUpAll(() {
    registerFallbackValue(DateTime(2020));
  });

  group('HubCubit', () {
    late HubCubit hubCubit;
    late MockExperimentManager mockExperimentManager;
    late MockDiaryRepository mockDiaryRepository;

    setUp(() {
      mockExperimentManager = MockExperimentManager();
      mockDiaryRepository = MockDiaryRepository();
      // Create HubCubit with injected mocks so no real ObjectBox-backed
      // DiaryRepository is constructed in the test environment.
      hubCubit = HubCubit(
        experimentManager: mockExperimentManager,
        diaryRepository: mockDiaryRepository,
      );
    });

    tearDown(() {
      hubCubit.close();
    });

    test('initial state is HubInitial', () {
      expect(hubCubit.state, equals(const HubInitial()));
    });

    group('update', () {
      blocTest<HubCubit, HubState>(
        'emits [HubUpdating, HubUpdated(false), HubInitial] when ExperimentManager.update() returns false',
        build: () {
          when(() => mockExperimentManager.update())
              .thenAnswer((_) async => false);
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) => cubit.update(),
        expect: () => [
          const HubUpdating(),
          const HubUpdated(false),
          const HubInitial(),
        ],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(1);
        },
      );

      blocTest<HubCubit, HubState>(
        'emits [HubUpdating, HubUpdated(true), HubInitial] when ExperimentManager.update() returns true',
        build: () {
          when(() => mockExperimentManager.update())
              .thenAnswer((_) async => true);
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) => cubit.update(),
        expect: () => [
          const HubUpdating(),
          const HubUpdated(true),
          const HubInitial(),
        ],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(1);
        },
      );

      blocTest<HubCubit, HubState>(
        'handles exceptions by throwing the exception after emitting HubUpdating',
        build: () {
          when(() => mockExperimentManager.update())
              .thenThrow(Exception('Test exception'));
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) => cubit.update(),
        expect: () => [
          const HubUpdating(),
        ],
        errors: () => [
          isA<Exception>(),
        ],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(1);
        },
      );

      blocTest<HubCubit, HubState>(
        'can be called multiple times without issues',
        build: () {
          when(() => mockExperimentManager.update())
              .thenAnswer((_) async => false);
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) async {
          await cubit.update();
          await cubit.update();
          await cubit.update();
        },
        expect: () => [
          const HubUpdating(),
          const HubUpdated(false),
          const HubInitial(),
          const HubUpdating(),
          const HubUpdated(false),
          const HubInitial(),
          const HubUpdating(),
          const HubUpdated(false),
          const HubInitial(),
        ],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(3);
        },
      );

      blocTest<HubCubit, HubState>(
        'handles concurrent calls correctly',
        build: () {
          when(() => mockExperimentManager.update()).thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 10));
            return true;
          });
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) async {
          // Start multiple concurrent calls
          final futures = <Future<void>>[
            cubit.update(),
            cubit.update(),
          ];
          await Future.wait(futures);
        },
        expect: () => [
          const HubUpdating(),
          const HubUpdated(true),
          const HubInitial(),
          const HubUpdated(true),
          const HubInitial(),
        ],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(2);
        },
      );
    });

    group('hasPendingOrSubmittedToday', () {
      DiaryModel diaryWithStatus(DiaryStatus status) {
        final diary = MockDiaryModel();
        when(() => diary.status).thenReturn(status);
        return diary;
      }

      test('returns false when there are no diaries today', () {
        when(() => mockDiaryRepository.getDailyDiaries(any())).thenReturn([]);
        expect(hubCubit.hasPendingOrSubmittedToday(), isFalse);
      });

      test('returns true when a diary is pending submission (complete)', () {
        // Build the diary mocks (which call when() internally) before
        // stubbing getDailyDiaries to avoid a nested when() call.
        final diaries = [
          diaryWithStatus(DiaryStatus.idle),
          diaryWithStatus(DiaryStatus.complete),
        ];
        when(() => mockDiaryRepository.getDailyDiaries(any()))
            .thenReturn(diaries);
        expect(hubCubit.hasPendingOrSubmittedToday(), isTrue);
      });

      test('returns true when a diary is already submitted', () {
        final diaries = [diaryWithStatus(DiaryStatus.submitted)];
        when(() => mockDiaryRepository.getDailyDiaries(any()))
            .thenReturn(diaries);
        expect(hubCubit.hasPendingOrSubmittedToday(), isTrue);
      });

      test('returns false for idle/ongoing/missed diaries only', () {
        final diaries = [
          diaryWithStatus(DiaryStatus.idle),
          diaryWithStatus(DiaryStatus.ongoing),
          diaryWithStatus(DiaryStatus.missed),
        ];
        when(() => mockDiaryRepository.getDailyDiaries(any()))
            .thenReturn(diaries);
        expect(hubCubit.hasPendingOrSubmittedToday(), isFalse);
      });
    });

    group('state equality', () {
      test('HubInitial instances are equal', () {
        const state1 = HubInitial();
        const state2 = HubInitial();
        expect(state1, equals(state2));
      });

      test('HubUpdating instances are equal', () {
        const state1 = HubUpdating();
        const state2 = HubUpdating();
        expect(state1, equals(state2));
      });

      test('HubUpdated instances are equal when complete values match', () {
        const state1 = HubUpdated(true);
        const state2 = HubUpdated(true);
        expect(state1, equals(state2));
      });

      test('HubUpdated instances are not equal when complete values differ',
          () {
        const state1 = HubUpdated(true);
        const state2 = HubUpdated(false);
        expect(state1, isNot(equals(state2)));
      });

      test('different state types are not equal', () {
        const initial = HubInitial();
        const updating = HubUpdating();
        const updated = HubUpdated(true);

        expect(initial, isNot(equals(updating)));
        expect(initial, isNot(equals(updated)));
        expect(updating, isNot(equals(updated)));
      });
    });
  });
}
