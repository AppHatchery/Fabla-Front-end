import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/diary_history_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_diaries_flutter/main.dart' as main_app;
import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/objectbox.g.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/protocol_entity.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/study.dart';

class MockDiaryRepository extends Mock implements DiaryRepository {}

class MockObjectBox extends Mock implements ObjectBox {
  @override
  late final Store store = MockStore();
}

class MockStore extends Mock implements Store {
  @override
  Box<T> box<T>() {
    if (T == Diary) {
      return MockDiaryBox() as Box<T>;
    } else if (T == ProtocolEntity) {
      return MockProtocolBox() as Box<T>;
    } else if (T == Study) {
      return MockStudyBox() as Box<T>;
    }
    throw UnimplementedError('Unexpected box type: $T');
  }
}

class MockDiaryBox extends Mock implements Box<Diary> {}

class MockProtocolBox extends Mock implements Box<ProtocolEntity> {}

class MockStudyBox extends Mock implements Box<Study> {}

void main() {
  late MockDiaryRepository mockDiaryRepository;

  // Test data
  final testDiary1 = DiaryModel(
    id: 1,
    studyID: 1,
    name: 'Morning Diary',
    status: DiaryStatus.submitted,
    start: DateTime(2023, 1, 1, 9),
    due: DateTime(2023, 1, 1, 11),
    prompts: const [],
    activeDays: const [1, 2, 3, 4, 5, 6, 7],
    tags: const [],
    entries: 1,
    currentEntry: 1,
    end: DateTime(2023, 1, 1, 11),
    notifications: const [],
  );

  final testDiary2 = DiaryModel(
    id: 2,
    studyID: 1,
    name: 'Evening Diary',
    status: DiaryStatus.submitted,
    start: DateTime(2023, 1, 1, 18),
    due: DateTime(2023, 1, 1, 20),
    prompts: const [],
    activeDays: const [1, 2, 3, 4, 5, 6, 7],
    tags: const [],
    entries: 1,
    currentEntry: 1,
    end: DateTime(2023, 1, 1, 20),
    notifications: const [],
  );

  final testDiary3 = DiaryModel(
    id: 3,
    studyID: 1,
    name: 'Yesterday Diary',
    status: DiaryStatus.missed,
    start: DateTime(2022, 12, 31, 15),
    due: DateTime(2022, 12, 31, 17),
    prompts: const [],
    activeDays: const [1, 2, 3, 4, 5, 6, 7],
    tags: const [],
    entries: 0,
    currentEntry: 0,
    end: DateTime(2022, 12, 31, 17),
    notifications: const [],
  );

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock SharedPreferences for any potential usage
    SharedPreferences.setMockInitialValues({});

    // Initialize mock ObjectBox to avoid the global objectbox dependency
    final mockObjectBox = MockObjectBox();
    main_app.objectbox = mockObjectBox;

    registerFallbackValue(DateTime(0));
  });

  setUp(() {
    mockDiaryRepository = MockDiaryRepository();
  });

  group('DiaryHistoryCubit Unit Tests', () {
    group('loadPastDiaries method tests', () {
      late DiaryHistoryCubit diaryHistoryCubit;

      setUp(() {
        // Create cubit and immediately replace repository with mock
        diaryHistoryCubit = DiaryHistoryCubit();
        diaryHistoryCubit.repository = mockDiaryRepository;
      });

      tearDown(() {
        diaryHistoryCubit.close();
      });

      test('initial state is DiaryHistoryInitial', () {
        expect(diaryHistoryCubit.state, const DiaryHistoryInitial());
      });

      blocTest<DiaryHistoryCubit, DiaryHistoryState>(
        'emits [DiaryHistoryLoading, DiaryHistoryLoaded] when loadPastDiaries succeeds with grouped diaries',
        setUp: () {
          final mockHistoryData = {
            '2023-01-01': [testDiary1, testDiary2],
            '2022-12-31': [testDiary3],
          };
          when(() => mockDiaryRepository.getAllHistoryDiaries())
              .thenReturn(mockHistoryData);
        },
        build: () => diaryHistoryCubit,
        act: (cubit) => cubit.loadPastDiaries(),
        expect: () => [
          const DiaryHistoryLoading(),
          isA<DiaryHistoryLoaded>(),
        ],
        verify: (cubit) {
          final state = cubit.state;
          expect(state, isA<DiaryHistoryLoaded>());
          final loadedState = state as DiaryHistoryLoaded;

          // Verify the grouped diaries structure
          expect(loadedState.groupedDiaries.length, 2);
          expect(loadedState.groupedDiaries.containsKey('2023-01-01'), true);
          expect(loadedState.groupedDiaries.containsKey('2022-12-31'), true);

          // Verify diaries for 2023-01-01
          final jan1Diaries = loadedState.groupedDiaries['2023-01-01']!;
          expect(jan1Diaries.length, 2);
          expect(jan1Diaries.first.id, 1);
          expect(jan1Diaries.first.name, 'Morning Diary');
          expect(jan1Diaries.first.status, DiaryStatus.submitted);
          expect(jan1Diaries.last.id, 2);
          expect(jan1Diaries.last.name, 'Evening Diary');

          // Verify diaries for 2022-12-31
          final dec31Diaries = loadedState.groupedDiaries['2022-12-31']!;
          expect(dec31Diaries.length, 1);
          expect(dec31Diaries.first.id, 3);
          expect(dec31Diaries.first.name, 'Yesterday Diary');
          expect(dec31Diaries.first.status, DiaryStatus.missed);

          // Verify repository was called
          verify(() => mockDiaryRepository.getAllHistoryDiaries()).called(1);
        },
      );

      blocTest<DiaryHistoryCubit, DiaryHistoryState>(
        'emits [DiaryHistoryLoading, DiaryHistoryLoaded] when loadPastDiaries succeeds with empty history',
        setUp: () {
          when(() => mockDiaryRepository.getAllHistoryDiaries())
              .thenReturn(<String, List<DiaryModel>>{});
        },
        build: () => diaryHistoryCubit,
        act: (cubit) => cubit.loadPastDiaries(),
        expect: () => [
          const DiaryHistoryLoading(),
          isA<DiaryHistoryLoaded>(),
        ],
        verify: (cubit) {
          final state = cubit.state;
          expect(state, isA<DiaryHistoryLoaded>());
          final loadedState = state as DiaryHistoryLoaded;

          // Verify empty history
          expect(loadedState.groupedDiaries.isEmpty, true);
          expect(loadedState.groupedDiaries.length, 0);

          // Verify repository was called
          verify(() => mockDiaryRepository.getAllHistoryDiaries()).called(1);
        },
      );

      blocTest<DiaryHistoryCubit, DiaryHistoryState>(
        'emits [DiaryHistoryLoading, DiaryHistoryLoaded] when loadPastDiaries succeeds with single date group',
        setUp: () {
          final mockHistoryData = {
            '2023-01-15': [testDiary1],
          };
          when(() => mockDiaryRepository.getAllHistoryDiaries())
              .thenReturn(mockHistoryData);
        },
        build: () => diaryHistoryCubit,
        act: (cubit) => cubit.loadPastDiaries(),
        expect: () => [
          const DiaryHistoryLoading(),
          isA<DiaryHistoryLoaded>(),
        ],
        verify: (cubit) {
          final state = cubit.state;
          expect(state, isA<DiaryHistoryLoaded>());
          final loadedState = state as DiaryHistoryLoaded;

          // Verify single date group
          expect(loadedState.groupedDiaries.length, 1);
          expect(loadedState.groupedDiaries.containsKey('2023-01-15'), true);

          final diaries = loadedState.groupedDiaries['2023-01-15']!;
          expect(diaries.length, 1);
          expect(diaries.first.id, 1);
          expect(diaries.first.name, 'Morning Diary');

          // Verify repository was called
          verify(() => mockDiaryRepository.getAllHistoryDiaries()).called(1);
        },
      );

      blocTest<DiaryHistoryCubit, DiaryHistoryState>(
        'emits [DiaryHistoryLoading, DiaryHistoryError] when loadPastDiaries throws an exception',
        setUp: () {
          when(() => mockDiaryRepository.getAllHistoryDiaries())
              .thenThrow(Exception('Database error'));
        },
        build: () => diaryHistoryCubit,
        act: (cubit) => cubit.loadPastDiaries(),
        expect: () => [
          const DiaryHistoryLoading(),
          const DiaryHistoryError('Something went wrong'),
        ],
        verify: (cubit) {
          final state = cubit.state;
          expect(state, isA<DiaryHistoryError>());
          final errorState = state as DiaryHistoryError;
          expect(errorState.message, 'Something went wrong');

          // Verify repository was called
          verify(() => mockDiaryRepository.getAllHistoryDiaries()).called(1);
        },
      );

      blocTest<DiaryHistoryCubit, DiaryHistoryState>(
        'emits [DiaryHistoryLoading, DiaryHistoryError] when loadPastDiaries throws a different exception',
        setUp: () {
          when(() => mockDiaryRepository.getAllHistoryDiaries())
              .thenThrow(StateError('Invalid state'));
        },
        build: () => diaryHistoryCubit,
        act: (cubit) => cubit.loadPastDiaries(),
        expect: () => [
          const DiaryHistoryLoading(),
          const DiaryHistoryError('Something went wrong'),
        ],
        verify: (cubit) {
          final state = cubit.state;
          expect(state, isA<DiaryHistoryError>());
          final errorState = state as DiaryHistoryError;
          expect(errorState.message, 'Something went wrong');

          // Verify repository was called
          verify(() => mockDiaryRepository.getAllHistoryDiaries()).called(1);
        },
      );

      group('different diary status scenarios', () {
        blocTest<DiaryHistoryCubit, DiaryHistoryState>(
          'handles mixed diary statuses correctly',
          setUp: () {
            final submittedDiary = testDiary1.copyWith(
              id: 1,
              studyID: 1,
              status: DiaryStatus.submitted,
            );
            final missedDiary = testDiary2.copyWith(
              id: 2,
              studyID: 1,
              status: DiaryStatus.missed,
            );
            final completeDiary = testDiary3.copyWith(
              id: 3,
              studyID: 1,
              status: DiaryStatus.complete,
            );

            final mockHistoryData = {
              '2023-01-01': [submittedDiary, missedDiary, completeDiary],
            };
            when(() => mockDiaryRepository.getAllHistoryDiaries())
                .thenReturn(mockHistoryData);
          },
          build: () => diaryHistoryCubit,
          act: (cubit) => cubit.loadPastDiaries(),
          expect: () => [
            const DiaryHistoryLoading(),
            isA<DiaryHistoryLoaded>(),
          ],
          verify: (cubit) {
            final state = cubit.state;
            expect(state, isA<DiaryHistoryLoaded>());
            final loadedState = state as DiaryHistoryLoaded;

            final diaries = loadedState.groupedDiaries['2023-01-01']!;
            expect(diaries.length, 3);

            // Verify different statuses are preserved
            expect(diaries[0].status, DiaryStatus.submitted);
            expect(diaries[1].status, DiaryStatus.missed);
            expect(diaries[2].status, DiaryStatus.complete);

            // Verify repository was called
            verify(() => mockDiaryRepository.getAllHistoryDiaries()).called(1);
          },
        );

        blocTest<DiaryHistoryCubit, DiaryHistoryState>(
          'handles large number of grouped diaries',
          setUp: () {
            final mockHistoryData = <String, List<DiaryModel>>{};

            // Create multiple date groups with multiple diaries each
            for (int day = 1; day <= 5; day++) {
              final dateKey = '2023-01-0$day';
              final diariesForDate = <DiaryModel>[];

              for (int i = 1; i <= 3; i++) {
                diariesForDate.add(DiaryModel(
                  id: (day * 10) + i,
                  studyID: 1,
                  name: 'Diary $day-$i',
                  status: i == 1 ? DiaryStatus.submitted : DiaryStatus.missed,
                  start: DateTime(2023, 1, day, 9 + i),
                  due: DateTime(2023, 1, day, 11 + i),
                  prompts: const [],
                  activeDays: const [1, 2, 3, 4, 5, 6, 7],
                  tags: const [],
                  entries: i,
                  currentEntry: i,
                  end: DateTime(2023, 1, day, 11 + i),
                  notifications: const [],
                ));
              }

              mockHistoryData[dateKey] = diariesForDate;
            }

            when(() => mockDiaryRepository.getAllHistoryDiaries())
                .thenReturn(mockHistoryData);
          },
          build: () => diaryHistoryCubit,
          act: (cubit) => cubit.loadPastDiaries(),
          expect: () => [
            const DiaryHistoryLoading(),
            isA<DiaryHistoryLoaded>(),
          ],
          verify: (cubit) {
            final state = cubit.state;
            expect(state, isA<DiaryHistoryLoaded>());
            final loadedState = state as DiaryHistoryLoaded;

            // Verify we have 5 date groups
            expect(loadedState.groupedDiaries.length, 5);

            // Verify each group has 3 diaries
            for (int day = 1; day <= 5; day++) {
              final dateKey = '2023-01-0$day';
              expect(loadedState.groupedDiaries.containsKey(dateKey), true);
              expect(loadedState.groupedDiaries[dateKey]!.length, 3);

              // Verify diary details for first diary in each group
              final firstDiary = loadedState.groupedDiaries[dateKey]!.first;
              expect(firstDiary.id, (day * 10) + 1);
              expect(firstDiary.name, 'Diary $day-1');
              expect(firstDiary.status, DiaryStatus.submitted);
            }

            // Verify repository was called
            verify(() => mockDiaryRepository.getAllHistoryDiaries()).called(1);
          },
        );
      });
    });
  });
}
