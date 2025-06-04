// AnswerDAO Unit Test
// -----------------------------------------------------------------------------
// This file contains a complete, self-contained unit test suite for the
// `AnswerDAO` class.  The aim is to validate that the DAO correctly issues
// the expected ObjectBox calls for each CRUD operation *without* ever touching
// a real database.  To achieve this we:
//   • Use `mocktail` to create mocks for the ObjectBox `Box`, `QueryBuilder`,
//     and `Query` classes.
//   • Inject those mocks into the DAO under test.
//   • Exercise each public method and assert that the right ObjectBox APIs are
//     invoked with the right arguments.
//
// The Arrange–Act–Assert pattern is followed inside every test so that each
// section's intent is crystal-clear.
// -----------------------------------------------------------------------------

import 'package:audio_diaries_flutter/core/database/dao/diary_dao.dart';
import 'package:audio_diaries_flutter/objectbox.g.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart'
    as entity;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockDiaryBox extends Mock implements Box<entity.Diary> {}

class MockDiaryQueryBuilder extends Mock
    implements QueryBuilder<entity.Diary> {}

class MockDiaryQuery extends Mock implements Query<entity.Diary> {}

class MockQueryDateProperty extends Mock
    implements QueryDateProperty<entity.Diary> {
  @override
  Condition<entity.Diary> greaterOrEqual(int value, {String? alias}) =>
      MockCondition();

  @override
  Condition<entity.Diary> lessThan(int value, {String? alias}) =>
      MockCondition();
}

class MockCondition extends Mock implements Condition<entity.Diary> {
  @override
  Condition<entity.Diary> and(Condition<entity.Diary> other) => this;
}

class FakeCondition extends Fake implements Condition<entity.Diary> {}

// Mock for Diary_ class
class MockDiary_ extends Mock {
  final MockQueryDateProperty _startProperty = MockQueryDateProperty();

  QueryDateProperty<entity.Diary> get start => _startProperty;
}

void main() {
  late DiaryDAO diaryDAO;
  late MockDiaryBox mockDiaryBox;
  late MockDiaryQueryBuilder mockDiaryQueryBuilder;
  late MockDiaryQuery mockDiaryQuery;
  late MockDiary_ mockDiary_;

  // Helper function to create a test diary with all required parameters
  entity.Diary createTestDiary({
    int id = 1,
    int studyID = 1,
    String name = 'Test Diary',
    DateTime? due,
    DateTime? start,
    int entries = 1,
    int currentEntry = 0,
    DateTime? end,
    String deadline = '2024-12-31',
    String notifications = '[]',
    List<int> activeDays = const [1, 2, 3],
  }) {
    final now = DateTime.now();
    return entity.Diary(
      id: id,
      studyID: studyID,
      name: name,
      due: due ?? now,
      start: start ?? now,
      entries: entries,
      currentEntry: currentEntry,
      end: end ?? now.add(const Duration(days: 7)),
      deadline: deadline,
      notifications: notifications,
      activeDays: activeDays,
    );
  }

  setUpAll(() {
    registerFallbackValue(createTestDiary());
    registerFallbackValue(FakeCondition());
  });

  setUp(() {
    mockDiaryBox = MockDiaryBox();
    mockDiaryQueryBuilder = MockDiaryQueryBuilder();
    mockDiaryQuery = MockDiaryQuery();
    mockDiary_ = MockDiary_();
    diaryDAO = DiaryDAO(box: mockDiaryBox);
  });

  group('DiaryDAO', () {
    test('getAllDiaries returns all diaries', () {
      final expectedDiaries = [createTestDiary()];

      when(() => mockDiaryBox.getAll()).thenReturn(expectedDiaries);

      final result = diaryDAO.getAllDiaries();

      expect(result, expectedDiaries);
      verify(() => mockDiaryBox.getAll()).called(1);
    });

    test('getDiaryByID returns a diary by ID', () {
      final diaryID = 1;
      final expectedDiary = createTestDiary(id: diaryID);

      when(() => mockDiaryBox.query(any())).thenReturn(mockDiaryQueryBuilder);
      when(() => mockDiaryQueryBuilder.build()).thenReturn(mockDiaryQuery);
      when(() => mockDiaryQuery.findFirst()).thenReturn(expectedDiary);

      final result = diaryDAO.getDiaryByID(diaryID);

      expect(result, expectedDiary);
      verify(() => mockDiaryBox.query(any())).called(1);
      verify(() => mockDiaryQueryBuilder.build()).called(1);
      verify(() => mockDiaryQuery.findFirst()).called(1);
    });

    test('addDiaries adds multiple diaries', () {
      final diariesToAdd = [
        createTestDiary(id: 1),
        createTestDiary(id: 2),
      ];

      when(() => mockDiaryBox.putMany(diariesToAdd)).thenReturn([]);

      diaryDAO.addDiaries(diariesToAdd);

      verify(() => mockDiaryBox.putMany(diariesToAdd)).called(1);
    });

    test('deleteAllDiaries removes all diaries', () {
      when(() => mockDiaryBox.removeAll()).thenReturn(1);

      final result = diaryDAO.deleteAllDiaries();

      expect(result, true);
      verify(() => mockDiaryBox.removeAll()).called(1);
    });

    test('getDailyDiary returns diaries for a specific day', () {
      final day = DateTime(2023, 10, 1);
      final expectedDiaries = [createTestDiary(due: day)];

      // Mock the query conditions
      when(() => mockDiaryBox.query(any())).thenReturn(mockDiaryQueryBuilder);
      when(() => mockDiaryQueryBuilder.build()).thenReturn(mockDiaryQuery);
      when(() => mockDiaryQuery.find()).thenReturn(expectedDiaries);
      when(() => mockDiaryQuery.close()).thenReturn(null);

      // Mock the Diary_.start property
      when(() => Diary_.start).thenReturn(mockDiary_._startProperty);

      final result = diaryDAO.getDailyDiary(day);

      expect(result, expectedDiaries);
      verify(() => mockDiaryBox.query(any())).called(1);
      verify(() => mockDiaryQueryBuilder.build()).called(1);
      verify(() => mockDiaryQuery.find()).called(1);
      verify(() => mockDiaryQuery.close()).called(1);
    });
  });
}
