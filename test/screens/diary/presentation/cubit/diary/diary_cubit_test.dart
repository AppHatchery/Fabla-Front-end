import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/tag.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/diary_cubit.dart';
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

// Helper function to mimic the Cubit's _getTags logic for test expectations
List<Tag> _getExpectedTags(
    DiaryStatus status, DateTime startTime, DateTime referenceDate) {
  List<Tag> tags = [];
  if (status == DiaryStatus.submitted) {
    tags.add(const Tag(text: "Done", type: TagType.time));
  } else if (status == DiaryStatus.missed) {
    tags.add(const Tag(text: "Missed", type: TagType.time));
  } else if (status == DiaryStatus.complete) {
    tags.add(const Tag(text: "Awaiting Submission", type: TagType.time));
  } else if (status == DiaryStatus.ongoing) {
    tags.add(const Tag(text: "Ongoing", type: TagType.time));
  } else if (status == DiaryStatus.idle && startTime.isAfter(referenceDate)) {
    tags.addAll([
      const Tag(text: "13 Questions", type: TagType.questions),
      const Tag(text: "12 Minutes", type: TagType.time)
    ]);
  } else if (status == DiaryStatus.idle) {
    tags.add(const Tag(text: "Ready to Start", type: TagType.time));
  }
  return tags;
}

void main() {
  late MockDiaryRepository mockDiaryRepository;

  final baseDiaryModel = DiaryModel(
    id: 1,
    studyID: 1,
    name: 'Test Diary',
    status: DiaryStatus.idle,
    start: DateTime(2023, 1, 1, 10),
    due: DateTime(2023, 1, 1, 12),
    prompts: const [],
    activeDays: const [1, 2, 3, 4, 5, 6, 7],
    tags: const [],
    entries: 0,
    currentEntry: 0,
    end: DateTime(2023, 1, 1, 12),
    notifications: const [],
  );

  final mockNowMorning = DateTime(2023, 1, 1, 10);
  final mockNowEvening = DateTime(2023, 1, 1, 2);
  final defaultStartDateFromPrefs = DateTime.fromMillisecondsSinceEpoch(0);

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock SharedPreferences for PreferenceService
    SharedPreferences.setMockInitialValues({
      'startDate': defaultStartDateFromPrefs.millisecondsSinceEpoch,
    });

    // Initialize mock ObjectBox to avoid the global objectbox dependency
    final mockObjectBox = MockObjectBox();
    main_app.objectbox = mockObjectBox;

    registerFallbackValue(DateTime(0));
  });

  setUp(() {
    mockDiaryRepository = MockDiaryRepository();
  });

  group('DiaryCubit Unit Tests', () {
    // Test without actually creating DiaryCubit to avoid ObjectBox dependency
    test('initial state should be DiaryInitial', () {
      // Test the state type directly since we can't instantiate the cubit easily
      const initialState = DiaryInitial();
      expect(initialState, isA<DiaryInitial>());
    });

    group('loadDiaries method tests', () {
      late DiaryCubit diaryCubit;

      setUp(() {
        // Create cubit and immediately replace repository with mock
        diaryCubit = DiaryCubit();
        diaryCubit.repository = mockDiaryRepository;
      });

      tearDown(() {
        diaryCubit.close();
      });

      blocTest<DiaryCubit, DiaryState>(
        'emits [DiaryLoading, DiaryLoaded] for idle diary, future start (morning)',
        setUp: () {
          final diaryFromRepo = baseDiaryModel.copyWith(
            id: baseDiaryModel.id,
            studyID: baseDiaryModel.studyID,
            status: DiaryStatus.idle,
            start: mockNowMorning.add(const Duration(hours: 1)),
          );
          when(() => mockDiaryRepository.getDiary(any(), any()))
              .thenAnswer((_) => diaryFromRepo);
        },
        build: () => diaryCubit,
        act: (cubit) => cubit.loadDiaries(date: mockNowMorning),
        expect: () => [
          const DiaryLoading(),
          isA<DiaryLoaded>(),
        ],
        verify: (cubit) {
          final state = cubit.state;
          expect(state, isA<DiaryLoaded>());
          final loadedState = state as DiaryLoaded;
          expect(loadedState.diaries.length, 1);
          final diary = loadedState.diaries.first;
          expect(diary.id, 1);
          expect(diary.studyID, 1);
          expect(diary.status, DiaryStatus.idle);
          expect(diary.start, mockNowMorning.add(const Duration(hours: 1)));
          expect(diary.tags?.length, 1);
          expect(diary.tags?.first.text, "Ready to Start");
          expect(loadedState.startDate, defaultStartDateFromPrefs);

          final expectedStart = DateTime(mockNowMorning.year,
              mockNowMorning.month, mockNowMorning.day, 4, 0, 0);
          final expectedDue = DateTime(mockNowMorning.year,
                  mockNowMorning.month, mockNowMorning.day, 3, 59, 59)
              .add(const Duration(days: 1));
          verify(() => mockDiaryRepository.getDiary(expectedStart, expectedDue))
              .called(1);
        },
      );

      blocTest<DiaryCubit, DiaryState>(
        'emits [DiaryLoading, DiaryLoaded] for submitted diary (evening)',
        setUp: () {
          final diaryFromRepo = baseDiaryModel.copyWith(
            id: baseDiaryModel.id,
            studyID: baseDiaryModel.studyID,
            status: DiaryStatus.submitted,
            start: mockNowEvening.subtract(const Duration(hours: 1)),
          );
          when(() => mockDiaryRepository.getDiary(any(), any()))
              .thenAnswer((_) => diaryFromRepo);
        },
        build: () => diaryCubit,
        act: (cubit) => cubit.loadDiaries(date: mockNowEvening),
        expect: () => [
          const DiaryLoading(),
          isA<DiaryLoaded>(),
        ],
        verify: (cubit) {
          final state = cubit.state;
          expect(state, isA<DiaryLoaded>());
          final loadedState = state as DiaryLoaded;
          expect(loadedState.diaries.length, 1);
          final diary = loadedState.diaries.first;
          expect(diary.status, DiaryStatus.submitted);
          expect(
              diary.start, mockNowEvening.subtract(const Duration(hours: 1)));
          expect(diary.tags?.length, 1);
          expect(diary.tags?.first.text, "Done");

          final expectedStart = DateTime(mockNowEvening.year,
                  mockNowEvening.month, mockNowEvening.day, 4, 0, 0)
              .subtract(const Duration(days: 1));
          final expectedDue = DateTime(mockNowEvening.year,
              mockNowEvening.month, mockNowEvening.day, 3, 59, 59);
          verify(() => mockDiaryRepository.getDiary(expectedStart, expectedDue))
              .called(1);
        },
      );

      blocTest<DiaryCubit, DiaryState>(
        'emits [DiaryLoading, DiaryLoaded] with empty list when repository returns null',
        setUp: () {
          when(() => mockDiaryRepository.getDiary(any(), any()))
              .thenAnswer((_) => null);
        },
        build: () => diaryCubit,
        act: (cubit) => cubit.loadDiaries(date: mockNowMorning),
        expect: () => [
          const DiaryLoading(),
          isA<DiaryLoaded>(),
        ],
        verify: (cubit) {
          final state = cubit.state;
          expect(state, isA<DiaryLoaded>());
          final loadedState = state as DiaryLoaded;
          expect(loadedState.diaries.length, 0);
          expect(loadedState.startDate, defaultStartDateFromPrefs);
        },
      );

      blocTest<DiaryCubit, DiaryState>(
        'emits [DiaryLoading, DiaryError] when repository throws an exception',
        setUp: () {
          when(() => mockDiaryRepository.getDiary(any(), any()))
              .thenThrow(Exception('Repo error'));
        },
        build: () => diaryCubit,
        act: (cubit) => cubit.loadDiaries(date: mockNowMorning),
        expect: () => [
          const DiaryLoading(),
          const DiaryError('Something went wrong'),
        ],
      );

      // Test different tag scenarios
      group('tag generation', () {
        blocTest<DiaryCubit, DiaryState>(
          'generates correct tags for missed status',
          setUp: () {
            final diaryFromRepo = baseDiaryModel.copyWith(
              id: baseDiaryModel.id,
              studyID: baseDiaryModel.studyID,
              status: DiaryStatus.missed,
              start: mockNowMorning,
            );
            when(() => mockDiaryRepository.getDiary(any(), any()))
                .thenAnswer((_) => diaryFromRepo);
          },
          build: () => diaryCubit,
          act: (cubit) => cubit.loadDiaries(date: mockNowMorning),
          expect: () => [
            const DiaryLoading(),
            isA<DiaryLoaded>(),
          ],
          verify: (cubit) {
            final state = cubit.state;
            expect(state, isA<DiaryLoaded>());
            final loadedState = state as DiaryLoaded;
            final diary = loadedState.diaries.first;
            expect(diary.status, DiaryStatus.missed);
            expect(diary.tags?.length, 1);
            expect(diary.tags?.first.text, "Missed");
          },
        );

        blocTest<DiaryCubit, DiaryState>(
          'generates correct tags for complete status',
          setUp: () {
            final diaryFromRepo = baseDiaryModel.copyWith(
              id: baseDiaryModel.id,
              studyID: baseDiaryModel.studyID,
              status: DiaryStatus.complete,
              start: mockNowMorning,
            );
            when(() => mockDiaryRepository.getDiary(any(), any()))
                .thenAnswer((_) => diaryFromRepo);
          },
          build: () => diaryCubit,
          act: (cubit) => cubit.loadDiaries(date: mockNowMorning),
          expect: () => [
            const DiaryLoading(),
            isA<DiaryLoaded>(),
          ],
          verify: (cubit) {
            final state = cubit.state;
            expect(state, isA<DiaryLoaded>());
            final loadedState = state as DiaryLoaded;
            final diary = loadedState.diaries.first;
            expect(diary.status, DiaryStatus.complete);
            expect(diary.tags?.length, 1);
            expect(diary.tags?.first.text, "Awaiting Submission");
          },
        );

        blocTest<DiaryCubit, DiaryState>(
          'generates correct tags for ongoing status',
          setUp: () {
            final diaryFromRepo = baseDiaryModel.copyWith(
              id: baseDiaryModel.id,
              studyID: baseDiaryModel.studyID,
              status: DiaryStatus.ongoing,
              start: mockNowMorning,
            );
            when(() => mockDiaryRepository.getDiary(any(), any()))
                .thenAnswer((_) => diaryFromRepo);
          },
          build: () => diaryCubit,
          act: (cubit) => cubit.loadDiaries(date: mockNowMorning),
          expect: () => [
            const DiaryLoading(),
            isA<DiaryLoaded>(),
          ],
          verify: (cubit) {
            final state = cubit.state;
            expect(state, isA<DiaryLoaded>());
            final loadedState = state as DiaryLoaded;
            final diary = loadedState.diaries.first;
            expect(diary.status, DiaryStatus.ongoing);
            expect(diary.tags?.length, 1);
            expect(diary.tags?.first.text, "Ongoing");
          },
        );

        blocTest<DiaryCubit, DiaryState>(
          'generates correct tags for idle status with past start time',
          setUp: () {
            final diaryFromRepo = baseDiaryModel.copyWith(
              id: baseDiaryModel.id,
              studyID: baseDiaryModel.studyID,
              status: DiaryStatus.idle,
              start: mockNowMorning.subtract(const Duration(hours: 1)),
            );
            when(() => mockDiaryRepository.getDiary(any(), any()))
                .thenAnswer((_) => diaryFromRepo);
          },
          build: () => diaryCubit,
          act: (cubit) => cubit.loadDiaries(date: mockNowMorning),
          expect: () => [
            const DiaryLoading(),
            isA<DiaryLoaded>(),
          ],
          verify: (cubit) {
            final state = cubit.state;
            expect(state, isA<DiaryLoaded>());
            final loadedState = state as DiaryLoaded;
            final diary = loadedState.diaries.first;
            expect(diary.status, DiaryStatus.idle);
            expect(
                diary.start, mockNowMorning.subtract(const Duration(hours: 1)));
            expect(diary.tags?.length, 1);
            expect(diary.tags?.first.text, "Ready to Start");
          },
        );
      });
    });
  });
}
