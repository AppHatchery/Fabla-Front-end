import 'package:audio_diaries_flutter/core/usecases/experiment_manager.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/hub/presentation/cubit/hub_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExperimentManager extends Mock implements ExperimentManager {}

class MockDiaryRepository extends Mock implements DiaryRepository {}

class MockDiaryModel extends Mock implements DiaryModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2020));
    registerFallbackValue(UpdateStatus.none);
  });

  group('HubCubit', () {
    late HubCubit hubCubit;
    late MockExperimentManager mockExperimentManager;
    late MockDiaryRepository mockDiaryRepository;

    setUp(() {
      mockExperimentManager = MockExperimentManager();
      mockDiaryRepository = MockDiaryRepository();
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
        'emits [HubUpdating, HubUpdated] and clears update status when update() returns true',
        build: () {
          when(() => mockExperimentManager.update())
              .thenAnswer((_) async => true);
          when(() => mockExperimentManager.setUpdateStatus(any()))
              .thenAnswer((_) async {});
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) => cubit.update(),
        expect: () => [
          const HubUpdating(),
          HubUpdated(),
        ],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(1);
          verify(() => mockExperimentManager.setUpdateStatus(UpdateStatus.none))
              .called(1);
        },
      );

      blocTest<HubCubit, HubState>(
        'emits [HubUpdating, HubUpdateFailed, HubInitial] when update() returns false',
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
          const HubUpdateFailed(connectionError: false),
          const HubInitial(),
        ],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(1);
        },
      );

      blocTest<HubCubit, HubState>(
        'emits [HubUpdating, HubUpdateFailed(connectionError: true), HubInitial] when update() returns null',
        build: () {
          when(() => mockExperimentManager.update())
              .thenAnswer((_) async => null);
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) => cubit.update(),
        expect: () => [
          const HubUpdating(),
          const HubUpdateFailed(connectionError: true),
          const HubInitial(),
        ],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(1);
        },
      );

      blocTest<HubCubit, HubState>(
        'handles exceptions by throwing after emitting HubUpdating',
        build: () {
          when(() => mockExperimentManager.update())
              .thenThrow(Exception('Test exception'));
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) => cubit.update(),
        expect: () => [const HubUpdating()],
        errors: () => [isA<Exception>()],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(1);
        },
      );

      blocTest<HubCubit, HubState>(
        'can be called multiple times sequentially',
        build: () {
          when(() => mockExperimentManager.update())
              .thenAnswer((_) async => false);
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) async {
          cubit.update();
          await Future.delayed(const Duration(milliseconds: 20));
          cubit.update();
          await Future.delayed(const Duration(milliseconds: 20));
          cubit.update();
          await Future.delayed(const Duration(milliseconds: 20));
        },
        expect: () => [
          const HubUpdating(),
          const HubUpdateFailed(connectionError: false),
          const HubInitial(),
          const HubUpdating(),
          const HubUpdateFailed(connectionError: false),
          const HubInitial(),
          const HubUpdating(),
          const HubUpdateFailed(connectionError: false),
          const HubInitial(),
        ],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(3);
        },
      );

      blocTest<HubCubit, HubState>(
        'handles concurrent calls — second HubUpdating is deduplicated',
        build: () {
          when(() => mockExperimentManager.update()).thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 10));
            return false;
          });
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) async {
          cubit.update();
          cubit.update();
          await Future.delayed(const Duration(milliseconds: 50));
        },
        expect: () => [
          const HubUpdating(),
          const HubUpdateFailed(connectionError: false),
          const HubInitial(),
          const HubUpdateFailed(connectionError: false),
          const HubInitial(),
        ],
        verify: (_) {
          verify(() => mockExperimentManager.update()).called(2);
        },
      );
    });

    group('checkForUpdates', () {
      blocTest<HubCubit, HubState>(
        'emits nothing when status is none',
        build: () {
          when(() => mockExperimentManager.checkForUpdates())
              .thenAnswer((_) async => UpdateStatus.none);
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) => cubit.checkForUpdates(),
        expect: () => [],
      );

      blocTest<HubCubit, HubState>(
        'emits HubUpdateAvailable when status is available and no blocking diaries',
        build: () {
          when(() => mockExperimentManager.checkForUpdates())
              .thenAnswer((_) async => UpdateStatus.available);
          when(() => mockDiaryRepository.getDailyDiaries(any()))
              .thenReturn([]);
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) => cubit.checkForUpdates(),
        expect: () => [HubUpdateAvailable()],
      );

      blocTest<HubCubit, HubState>(
        'reschedules and suppresses HubUpdateAvailable when update is available but diaries are ongoing',
        build: () {
          final diary = MockDiaryModel();
          when(() => diary.status).thenReturn(DiaryStatus.ongoing);

          when(() => mockExperimentManager.checkForUpdates())
              .thenAnswer((_) async => UpdateStatus.available);
          when(() => mockDiaryRepository.getDailyDiaries(any()))
              .thenReturn([diary]);
          when(() => mockExperimentManager.reschedule()).thenAnswer(
              (_) async => DateTime.now().add(const Duration(days: 1)));
          // Return empty so _rescheduleWithNotification exits before scheduling a notification.
          when(() => mockDiaryRepository.getDiaries(any())).thenReturn([]);
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) => cubit.checkForUpdates(),
        expect: () => [],
        verify: (_) {
          verify(() => mockExperimentManager.reschedule()).called(1);
        },
      );

      blocTest<HubCubit, HubState>(
        'reschedules and suppresses HubUpdateAvailable when update is available but diaries are complete',
        build: () {
          final diary = MockDiaryModel();
          when(() => diary.status).thenReturn(DiaryStatus.complete);

          when(() => mockExperimentManager.checkForUpdates())
              .thenAnswer((_) async => UpdateStatus.available);
          when(() => mockDiaryRepository.getDailyDiaries(any()))
              .thenReturn([diary]);
          when(() => mockExperimentManager.reschedule()).thenAnswer(
              (_) async => DateTime.now().add(const Duration(days: 1)));
          when(() => mockDiaryRepository.getDiaries(any())).thenReturn([]);
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) => cubit.checkForUpdates(),
        expect: () => [],
        verify: (_) {
          verify(() => mockExperimentManager.reschedule()).called(1);
        },
      );

      blocTest<HubCubit, HubState>(
        'emits nothing when status is pending and pending date has not arrived',
        build: () {
          when(() => mockExperimentManager.checkForUpdates())
              .thenAnswer((_) async => UpdateStatus.pending);
          when(() => mockExperimentManager.getPendingDate()).thenAnswer(
              (_) async => DateTime.now().add(const Duration(hours: 2)));
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) => cubit.checkForUpdates(),
        expect: () => [],
      );

      blocTest<HubCubit, HubState>(
        'emits nothing when status is pending and pending date is null',
        build: () {
          when(() => mockExperimentManager.checkForUpdates())
              .thenAnswer((_) async => UpdateStatus.pending);
          when(() => mockExperimentManager.getPendingDate())
              .thenAnswer((_) async => null);
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) => cubit.checkForUpdates(),
        expect: () => [],
      );

      blocTest<HubCubit, HubState>(
        'emits HubUpdateAvailable when pending date has passed and no blocking diaries',
        build: () {
          when(() => mockExperimentManager.checkForUpdates())
              .thenAnswer((_) async => UpdateStatus.pending);
          when(() => mockExperimentManager.getPendingDate()).thenAnswer(
              (_) async => DateTime.now().subtract(const Duration(hours: 1)));
          when(() => mockExperimentManager.setUpdateStatus(any()))
              .thenAnswer((_) async {});
          when(() => mockDiaryRepository.getDailyDiaries(any())).thenReturn([]);
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) => cubit.checkForUpdates(),
        expect: () => [HubUpdateAvailable()],
        verify: (_) {
          verify(() => mockExperimentManager
              .setUpdateStatus(UpdateStatus.available)).called(1);
        },
      );

      blocTest<HubCubit, HubState>(
        'reschedules when pending date has passed but diaries are ongoing/complete',
        build: () {
          final diary = MockDiaryModel();
          when(() => diary.status).thenReturn(DiaryStatus.ongoing);

          when(() => mockExperimentManager.checkForUpdates())
              .thenAnswer((_) async => UpdateStatus.pending);
          when(() => mockExperimentManager.getPendingDate()).thenAnswer(
              (_) async => DateTime.now().subtract(const Duration(hours: 1)));
          when(() => mockDiaryRepository.getDailyDiaries(any()))
              .thenReturn([diary]);
          when(() => mockExperimentManager.reschedule()).thenAnswer(
              (_) async => DateTime.now().add(const Duration(days: 1)));
          when(() => mockDiaryRepository.getDiaries(any())).thenReturn([]);
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) => cubit.checkForUpdates(),
        expect: () => [],
        verify: (_) {
          verify(() => mockExperimentManager.reschedule()).called(1);
        },
      );
    });

    group('scheduleForLater', () {
      blocTest<HubCubit, HubState>(
        'calls reschedule and emits nothing when there are no diaries on the pending day',
        build: () {
          when(() => mockExperimentManager.reschedule()).thenAnswer(
              (_) async => DateTime.now().add(const Duration(days: 1)));
          when(() => mockDiaryRepository.getDiaries(any())).thenReturn([]);
          return HubCubit(
            experimentManager: mockExperimentManager,
            diaryRepository: mockDiaryRepository,
          );
        },
        act: (cubit) => cubit.scheduleForLater(),
        expect: () => [],
        verify: (_) {
          verify(() => mockExperimentManager.reschedule()).called(1);
        },
      );
    });

    group('hasOngoingOrCompleteToday', () {
      // Build diary mocks before stubbing getDailyDiaries — calling when()
      // inside thenReturn's argument triggers mocktail's nested-recording guard.
      DiaryModel diaryWithStatus(DiaryStatus status) {
        final diary = MockDiaryModel();
        when(() => diary.status).thenReturn(status);
        return diary;
      }

      test('returns false when there are no diaries today', () {
        when(() => mockDiaryRepository.getDailyDiaries(any())).thenReturn([]);
        expect(hubCubit.hasOngoingOrCompleteToday(), isFalse);
      });

      test('returns true when a diary is ongoing', () {
        final diaries = [diaryWithStatus(DiaryStatus.ongoing)];
        when(() => mockDiaryRepository.getDailyDiaries(any()))
            .thenReturn(diaries);
        expect(hubCubit.hasOngoingOrCompleteToday(), isTrue);
      });

      test('returns true when a diary is complete (recorded, not submitted)', () {
        final diaries = [diaryWithStatus(DiaryStatus.complete)];
        when(() => mockDiaryRepository.getDailyDiaries(any()))
            .thenReturn(diaries);
        expect(hubCubit.hasOngoingOrCompleteToday(), isTrue);
      });

      test('returns true when a diary is submitted', () {
        final diaries = [diaryWithStatus(DiaryStatus.submitted)];
        when(() => mockDiaryRepository.getDailyDiaries(any()))
            .thenReturn(diaries);
        expect(hubCubit.hasOngoingOrCompleteToday(), isTrue);
      });

      test('returns false for idle/missed diaries', () {
        final diaries = [
          diaryWithStatus(DiaryStatus.idle),
          diaryWithStatus(DiaryStatus.missed),
        ];
        when(() => mockDiaryRepository.getDailyDiaries(any()))
            .thenReturn(diaries);
        expect(hubCubit.hasOngoingOrCompleteToday(), isFalse);
      });
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

      test('returns false for idle/ongoing/missed diaries', () {
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
        expect(const HubInitial(), equals(const HubInitial()));
      });

      test('HubUpdating instances are equal', () {
        expect(const HubUpdating(), equals(const HubUpdating()));
      });

      test('HubUpdated instances are equal', () {
        expect(HubUpdated(), equals(HubUpdated()));
      });

      test('HubUpdateAvailable instances are equal', () {
        expect(HubUpdateAvailable(), equals(HubUpdateAvailable()));
      });

      test('HubUpdateFailed instances with same connectionError are equal', () {
        expect(const HubUpdateFailed(connectionError: true),
            equals(const HubUpdateFailed(connectionError: true)));
      });

      test('HubUpdateFailed instances with different connectionError are not equal', () {
        expect(const HubUpdateFailed(connectionError: true),
            isNot(equals(const HubUpdateFailed(connectionError: false))));
      });

      test('different state types are not equal', () {
        const initial = HubInitial();
        const updating = HubUpdating();
        final updated = HubUpdated();
        final updateAvailable = HubUpdateAvailable();
        const updateFailed = HubUpdateFailed();

        expect(initial, isNot(equals(updating)));
        expect(initial, isNot(equals(updated)));
        expect(updating, isNot(equals(updated)));
        expect(updated, isNot(equals(updateAvailable)));
        expect(updated, isNot(equals(updateFailed)));
        expect(updateAvailable, isNot(equals(updateFailed)));
      });
    });
  });
}
