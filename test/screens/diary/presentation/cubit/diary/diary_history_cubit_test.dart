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
import 'package:audio_diaries_flutter/core/usecases/diary_history.dart';

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
    submissions: const [],
    completions: const [],
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
    submissions: const [],
    completions: const [],
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
    submissions: const [],
    completions: const [],
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
          final mockPaginatedResult = PaginatedDiaryResult(
            diaries: {
              '2023-01-01': [testDiary1, testDiary2],
              '2022-12-31': [testDiary3],
            },
            hasMore: false,
            totalCount: 3,
          );
          when(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: any(named: 'page'),
                limit: any(named: 'limit'),
              )).thenReturn(mockPaginatedResult);
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

          // Verify pagination state
          expect(loadedState.hasMore, false);
          expect(loadedState.currentPage, 0);

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

          // Verify repository was called with correct params
          verify(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 0,
                limit: 10,
              )).called(1);
        },
      );

      blocTest<DiaryHistoryCubit, DiaryHistoryState>(
        'emits [DiaryHistoryLoading, DiaryHistoryLoaded] when loadPastDiaries succeeds with empty history',
        setUp: () {
          final mockPaginatedResult = PaginatedDiaryResult(
            diaries: const <String, List<DiaryModel>>{},
            hasMore: false,
            totalCount: 0,
          );
          when(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: any(named: 'page'),
                limit: any(named: 'limit'),
              )).thenReturn(mockPaginatedResult);
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
          expect(loadedState.hasMore, false);
          expect(loadedState.currentPage, 0);

          // Verify repository was called
          verify(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 0,
                limit: 10,
              )).called(1);
        },
      );

      blocTest<DiaryHistoryCubit, DiaryHistoryState>(
        'emits [DiaryHistoryLoading, DiaryHistoryLoaded] with hasMore true when more pages exist',
        setUp: () {
          final mockPaginatedResult = PaginatedDiaryResult(
            diaries: {
              '2023-01-15': [testDiary1],
            },
            hasMore: true,
            totalCount: 10,
          );
          when(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: any(named: 'page'),
                limit: any(named: 'limit'),
              )).thenReturn(mockPaginatedResult);
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
          expect(loadedState.hasMore, true);
          expect(loadedState.currentPage, 0);

          final diaries = loadedState.groupedDiaries['2023-01-15']!;
          expect(diaries.length, 1);
          expect(diaries.first.id, 1);
          expect(diaries.first.name, 'Morning Diary');

          // Verify repository was called
          verify(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 0,
                limit: 10,
              )).called(1);
        },
      );

      blocTest<DiaryHistoryCubit, DiaryHistoryState>(
        'emits [DiaryHistoryLoading, DiaryHistoryError] when loadPastDiaries throws an exception',
        setUp: () {
          when(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: any(named: 'page'),
                limit: any(named: 'limit'),
              )).thenThrow(Exception('Database error'));
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
          verify(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 0,
                limit: 10,
              )).called(1);
        },
      );

      blocTest<DiaryHistoryCubit, DiaryHistoryState>(
        'emits [DiaryHistoryLoading, DiaryHistoryError] when loadPastDiaries throws a different exception',
        setUp: () {
          when(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: any(named: 'page'),
                limit: any(named: 'limit'),
              )).thenThrow(StateError('Invalid state'));
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
          verify(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 0,
                limit: 10,
              )).called(1);
        },
      );
    });

    group('loadMoreDiaries method tests', () {
      late DiaryHistoryCubit diaryHistoryCubit;

      setUp(() {
        diaryHistoryCubit = DiaryHistoryCubit();
        diaryHistoryCubit.repository = mockDiaryRepository;
      });

      tearDown(() {
        diaryHistoryCubit.close();
      });

      blocTest<DiaryHistoryCubit, DiaryHistoryState>(
        'emits [DiaryHistoryLoadingMore, DiaryHistoryLoaded] when loading more succeeds',
        setUp: () {
          // First page
          final firstPageResult = PaginatedDiaryResult(
            diaries: {
              '2023-01-01': [testDiary1],
            },
            hasMore: true,
            totalCount: 10,
          );

          // Second page
          final secondPageResult = PaginatedDiaryResult(
            diaries: {
              '2023-01-01': [testDiary2],
              '2022-12-31': [testDiary3],
            },
            hasMore: false,
            totalCount: 10,
          );

          when(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 0,
                limit: 10,
              )).thenReturn(firstPageResult);

          when(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 1,
                limit: 10,
              )).thenReturn(secondPageResult);
        },
        build: () => diaryHistoryCubit,
        act: (cubit) async {
          await cubit.loadPastDiaries();
          await cubit.loadMoreDiaries();
        },
        expect: () => [
          const DiaryHistoryLoading(),
          isA<DiaryHistoryLoaded>()
              .having((s) => s.currentPage, 'page', 0)
              .having((s) => s.hasMore, 'hasMore', true),
          isA<DiaryHistoryLoadingMore>(),
          isA<DiaryHistoryLoaded>()
              .having((s) => s.currentPage, 'page', 1)
              .having((s) => s.hasMore, 'hasMore', false),
        ],
        verify: (cubit) {
          final state = cubit.state;
          expect(state, isA<DiaryHistoryLoaded>());
          final loadedState = state as DiaryHistoryLoaded;

          // Verify merged data
          expect(loadedState.groupedDiaries.length, 2);
          expect(loadedState.groupedDiaries['2023-01-01']!.length, 2);
          expect(loadedState.groupedDiaries['2022-12-31']!.length, 1);
          expect(loadedState.currentPage, 1);
          expect(loadedState.hasMore, false);

          // Verify both pages were called
          verify(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 0,
                limit: 10,
              )).called(1);
          verify(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 1,
                limit: 10,
              )).called(1);
        },
      );

      blocTest<DiaryHistoryCubit, DiaryHistoryState>(
        'does not emit when loadMoreDiaries called with hasMore false',
        setUp: () {
          final result = PaginatedDiaryResult(
            diaries: {
              '2023-01-01': [testDiary1],
            },
            hasMore: false,
            totalCount: 1,
          );

          when(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 0,
                limit: 10,
              )).thenReturn(result);
        },
        build: () => diaryHistoryCubit,
        act: (cubit) async {
          await cubit.loadPastDiaries();
          await cubit.loadMoreDiaries();
        },
        expect: () => [
          const DiaryHistoryLoading(),
          isA<DiaryHistoryLoaded>().having((s) => s.hasMore, 'hasMore', false),
        ],
        verify: (cubit) {
          // loadMoreDiaries should not call repository since hasMore is false
          verify(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 0,
                limit: 10,
              )).called(1);
          verifyNever(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 1,
                limit: 10,
              ));
        },
      );

      blocTest<DiaryHistoryCubit, DiaryHistoryState>(
        'does not emit when loadMoreDiaries called from non-loaded state',
        build: () => diaryHistoryCubit,
        act: (cubit) => cubit.loadMoreDiaries(),
        expect: () => [],
        verify: (cubit) {
          // Should not call repository
          verifyNever(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: any(named: 'page'),
                limit: any(named: 'limit'),
              ));
        },
      );

      blocTest<DiaryHistoryCubit, DiaryHistoryState>(
        'reverts to previous state when loadMoreDiaries throws exception',
        setUp: () {
          final firstPageResult = PaginatedDiaryResult(
            diaries: {
              '2023-01-01': [testDiary1],
            },
            hasMore: true,
            totalCount: 10,
          );

          when(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 0,
                limit: 10,
              )).thenReturn(firstPageResult);

          when(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 1,
                limit: 10,
              )).thenThrow(Exception('Network error'));
        },
        build: () => diaryHistoryCubit,
        act: (cubit) async {
          await cubit.loadPastDiaries();
          await cubit.loadMoreDiaries();
        },
        expect: () => [
          const DiaryHistoryLoading(),
          isA<DiaryHistoryLoaded>()
              .having((s) => s.currentPage, 'page', 0)
              .having((s) => s.hasMore, 'hasMore', true),
          isA<DiaryHistoryLoadingMore>(),
          isA<DiaryHistoryLoaded>()
              .having((s) => s.currentPage, 'page', 0)
              .having((s) => s.hasMore, 'hasMore', true),
        ],
        verify: (cubit) {
          final state = cubit.state;
          expect(state, isA<DiaryHistoryLoaded>());
          final loadedState = state as DiaryHistoryLoaded;

          // Should revert to previous state
          expect(loadedState.currentPage, 0);
          expect(loadedState.hasMore, true);
          expect(loadedState.groupedDiaries['2023-01-01']!.length, 1);
        },
      );

      blocTest<DiaryHistoryCubit, DiaryHistoryState>(
        'merges diaries correctly across same date groups',
        setUp: () {
          final firstPageResult = PaginatedDiaryResult(
            diaries: {
              '2023-01-01': [testDiary1],
            },
            hasMore: true,
            totalCount: 10,
          );

          final secondPageResult = PaginatedDiaryResult(
            diaries: {
              '2023-01-01': [testDiary2],
            },
            hasMore: false,
            totalCount: 10,
          );

          when(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 0,
                limit: 10,
              )).thenReturn(firstPageResult);

          when(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 1,
                limit: 10,
              )).thenReturn(secondPageResult);
        },
        build: () => diaryHistoryCubit,
        act: (cubit) async {
          await cubit.loadPastDiaries();
          await cubit.loadMoreDiaries();
        },
        expect: () => [
          const DiaryHistoryLoading(),
          isA<DiaryHistoryLoaded>(),
          isA<DiaryHistoryLoadingMore>(),
          isA<DiaryHistoryLoaded>(),
        ],
        verify: (cubit) {
          final state = cubit.state;
          expect(state, isA<DiaryHistoryLoaded>());
          final loadedState = state as DiaryHistoryLoaded;

          // Verify both diaries are in the same date group
          expect(loadedState.groupedDiaries['2023-01-01']!.length, 2);
          expect(loadedState.groupedDiaries['2023-01-01']![0].id, 1);
          expect(loadedState.groupedDiaries['2023-01-01']![1].id, 2);
        },
      );
    });

    group('different diary status scenarios', () {
      late DiaryHistoryCubit diaryHistoryCubit;

      setUp(() {
        diaryHistoryCubit = DiaryHistoryCubit();
        diaryHistoryCubit.repository = mockDiaryRepository;
      });

      tearDown(() {
        diaryHistoryCubit.close();
      });

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

          final mockPaginatedResult = PaginatedDiaryResult(
            diaries: {
              '2023-01-01': [submittedDiary, missedDiary, completeDiary],
            },
            hasMore: false,
            totalCount: 3,
          );

          when(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: any(named: 'page'),
                limit: any(named: 'limit'),
              )).thenReturn(mockPaginatedResult);
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
          verify(() => mockDiaryRepository.getPaginatedHistoryDiaries(
                page: 0,
                limit: 10,
              )).called(1);
        },
      );
    });
  });
}
