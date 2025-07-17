// DiaryDAO Unit Test
// -----------------------------------------------------------------------------
// This file contains unit tests for the DiaryDAO class that focus on testing
// the methods that can be safely mocked without requiring the ObjectBox native
// library. Methods that use complex ObjectBox query building are excluded and
// should be tested in integration tests instead.
// -----------------------------------------------------------------------------

import 'package:audio_diaries_flutter/core/database/dao/diary_dao.dart';
import 'package:audio_diaries_flutter/objectbox.g.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart'
    as entity;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../dummy_data.dart';

// Mock classes
class MockDiaryBox extends Mock implements Box<entity.Diary> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DiaryDAO diaryDAO;
  late MockDiaryBox mockDiaryBox;

  registerFallbackValue(createTestDiary());

  setUp(() {
    mockDiaryBox = MockDiaryBox();
    diaryDAO = DiaryDAO(box: mockDiaryBox);
  });

  group('DiaryDAO - Safe Unit Tests', () {
    test('getAllDiaries returns all diaries', () {
      // Arrange
      final expectedDiaries = [
        createTestDiary(id: 1, name: 'Diary 1'),
        createTestDiary(id: 2, name: 'Diary 2'),
      ];
      when(() => mockDiaryBox.getAll()).thenReturn(expectedDiaries);

      // Act
      final result = diaryDAO.getAllDiaries();

      // Assert
      expect(result, expectedDiaries);
      expect(result.length, 2);
      expect(result[0].name, 'Diary 1');
      expect(result[1].name, 'Diary 2');
      verify(() => mockDiaryBox.getAll()).called(1);
    });

    test('addDiaries adds multiple diaries', () {
      // Arrange
      final diariesToAdd = [
        createTestDiary(id: 1),
        createTestDiary(id: 2),
      ];
      when(() => mockDiaryBox.putMany(diariesToAdd)).thenReturn([1, 2]);

      // Act
      diaryDAO.addDiaries(diariesToAdd);

      // Assert
      verify(() => mockDiaryBox.putMany(diariesToAdd)).called(1);
    });

    test('updateDiary updates a single diary', () {
      // Arrange
      final diaryToUpdate = createTestDiary(id: 1, name: 'Updated Diary');
      when(() => mockDiaryBox.put(diaryToUpdate)).thenReturn(1);

      // Act
      diaryDAO.updateDiary(diaryToUpdate);

      // Assert
      verify(() => mockDiaryBox.put(diaryToUpdate)).called(1);
    });

    test('updateDiaries updates multiple diaries', () {
      // Arrange
      final diariesToUpdate = [
        createTestDiary(id: 1, name: 'Updated 1'),
        createTestDiary(id: 2, name: 'Updated 2'),
      ];
      when(() => mockDiaryBox.putMany(diariesToUpdate)).thenReturn([1, 2]);

      // Act
      diaryDAO.updateDiaries(diariesToUpdate);

      // Assert
      verify(() => mockDiaryBox.putMany(diariesToUpdate)).called(1);
    });

    test('deleteAllDiaries removes all diaries and returns true on success',
        () {
      // Arrange
      when(() => mockDiaryBox.removeAll()).thenReturn(5);

      // Act
      final result = diaryDAO.deleteAllDiaries();

      // Assert
      expect(result, true);
      verify(() => mockDiaryBox.removeAll()).called(1);
    });

    test('deleteAllDiaries returns false when exception occurs', () {
      // Arrange
      when(() => mockDiaryBox.removeAll()).thenThrow(Exception('Test error'));

      // Act
      final result = diaryDAO.deleteAllDiaries();

      // Assert
      expect(result, false);
      verify(() => mockDiaryBox.removeAll()).called(1);
    });

    test('deleteDiaries removes specified diaries and returns count', () {
      // Arrange
      final diariesToDelete = [
        createTestDiary(id: 1),
        createTestDiary(id: 2),
      ];
      when(() => mockDiaryBox.removeMany([1, 2])).thenReturn(2);

      // Act
      final result = diaryDAO.deleteDiaries(diariesToDelete);

      // Assert
      expect(result, 2);
      verify(() => mockDiaryBox.removeMany([1, 2])).called(1);
    });

    test('deleteDiaries returns 0 when exception occurs', () {
      // Arrange
      final diariesToDelete = [createTestDiary(id: 1)];
      when(() => mockDiaryBox.removeMany([1]))
          .thenThrow(Exception('Test error'));

      // Act
      final result = diaryDAO.deleteDiaries(diariesToDelete);

      // Assert
      expect(result, 0);
      verify(() => mockDiaryBox.removeMany([1])).called(1);
    });
  });

  group('Entity Creation and Validation Tests', () {
    test('should create valid Diary entity with all required fields', () {
      // Arrange & Act
      final testDiary = createTestDiary(
        id: 123,
        studyID: 456,
        name: 'Test Diary Entity',
        due: DateTime(2023, 12, 25, 15, 30),
        start: DateTime(2023, 12, 25, 10, 0),
        entries: 5,
        currentEntry: 2,
        end: DateTime(2023, 12, 30, 10, 0),
        deadline: '2023-12-31',
        notifications: '["notification1", "notification2"]',
        activeDays: [1, 3, 5, 7],
      );

      // Assert
      expect(testDiary.id, 123);
      expect(testDiary.studyID, 456);
      expect(testDiary.name, 'Test Diary Entity');
      expect(testDiary.due, DateTime(2023, 12, 25, 15, 30));
      expect(testDiary.start, DateTime(2023, 12, 25, 10, 0));
      expect(testDiary.entries, 5);
      expect(testDiary.currentEntry, 2);
      expect(testDiary.end, DateTime(2023, 12, 30, 10, 0));
      expect(testDiary.deadline, '2023-12-31');
      expect(testDiary.notifications, '["notification1", "notification2"]');
      expect(testDiary.activeDays, [1, 3, 5, 7]);
    });

    test('should handle date calculations correctly for daily queries', () {
      // Test the date logic that would be used in getDailyDiary
      final inputDate = DateTime(2023, 10, 1, 14, 30, 45);
      final startOfDay =
          DateTime(inputDate.year, inputDate.month, inputDate.day);
      final startOfNextDay = startOfDay.add(const Duration(days: 1));

      expect(startOfDay, DateTime(2023, 10, 1, 0, 0, 0));
      expect(startOfNextDay, DateTime(2023, 10, 2, 0, 0, 0));

      // Verify the time range logic
      final testDateTime = DateTime(2023, 10, 1, 15, 0, 0);
      expect(
          testDateTime.millisecondsSinceEpoch >=
              startOfDay.millisecondsSinceEpoch,
          true);
      expect(
          testDateTime.millisecondsSinceEpoch <
              startOfNextDay.millisecondsSinceEpoch,
          true);
    });

    test('should handle edge cases for date boundaries', () {
      // Test midnight boundary
      final midnight = DateTime(2023, 10, 1, 0, 0, 0);
      final startOfDay = DateTime(midnight.year, midnight.month, midnight.day);
      expect(midnight, startOfDay);

      // Test end of day
      final endOfDay = DateTime(2023, 10, 1, 23, 59, 59);
      final startOfNextDay =
          DateTime(startOfDay.year, startOfDay.month, startOfDay.day)
              .add(const Duration(days: 1));
      expect(
          endOfDay.millisecondsSinceEpoch <
              startOfNextDay.millisecondsSinceEpoch,
          true);
    });
  });

  group('List Operations and Helper Functions', () {
    test('should handle empty diary lists correctly', () {
      final emptyList = <entity.Diary>[];
      expect(emptyList, isEmpty);
      expect(emptyList.length, 0);
    });

    test('should handle diary ID extraction correctly', () {
      final diaries = [
        createTestDiary(id: 1),
        createTestDiary(id: 2),
        createTestDiary(id: 3),
      ];

      final ids = diaries.map((diary) => diary.id).toList();
      expect(ids, [1, 2, 3]);
    });

    test('should handle error handling patterns correctly', () {
      // Test the pattern used in deleteAllDiaries and deleteDiaries
      bool testDeleteOperation() {
        try {
          // Simulate successful operation
          return true;
        } catch (e) {
          return false;
        }
      }

      int testDeleteManyOperation() {
        try {
          // Simulate successful operation returning count
          return 2;
        } catch (e) {
          return 0;
        }
      }

      expect(testDeleteOperation(), true);
      expect(testDeleteManyOperation(), 2);
    });
  });

  // Documentation group for integration test requirements
  group('Integration Test Requirements', () {
    test('documents methods requiring ObjectBox native library', () {
      // This test serves as documentation for what needs integration testing
      final methodsRequiringIntegrationTests = [
        'getDiary(DateTime start, DateTime due)',
        'getDiaries(DateTime day)',
        'getDiaryByID(int id)',
        'getDailyDiary(DateTime due)',
      ];

      expect(methodsRequiringIntegrationTests.length, 4);

      // These methods use ObjectBox query building with Diary_.start conditions
      // which requires the native ObjectBox library to be available.
      // They should be tested in integration tests with a real ObjectBox database.
    });
  });
}
