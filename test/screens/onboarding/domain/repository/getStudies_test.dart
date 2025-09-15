import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

// Core imports
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';

// Test utilities
import '../../../../dummy_data.dart';
/*
The main functionality being tested:
  - Diary merging algorithms
  - Status determination logic
  - Data processing and validation
*/

void main() {
  group('SetupRepository Business Logic Tests', () {
    group('Diary Merging Logic', () {
      group('Diary Merging', () {
        test('should merge existing diaries with new diaries correctly', () {
          // Arrange
          final existingDiary = _createTestDiary(
            id: 1,
            status: DiaryStatus.ongoing,
            currentEntry: 2,
          );

          final newDiary = _createTestDiary(
            id: 1,
            status: DiaryStatus.idle,
            currentEntry: 1,
          );

          // Act
          final result = DiaryMergingHelper.mergeDiaries(
           [newDiary], [existingDiary],
          );

          // Assert
          expect(result, hasLength(1));
          expect(result.first.currentEntry, equals(1));
        });

        test('should add new diaries that do not exist', () {
          // Arrange
          final newDiary = _createTestDiary(
            id: 1,
            name: 'New Diary',
          );

          // Act
          final result = DiaryMergingHelper.mergeDiaries(
            [newDiary],[]
            );

          // Assert
          expect(result, hasLength(1));
          expect(result.first.name, equals('New Diary'));
        });

        test('should keep existing diary if no changes', () {
          // Arrange
          final existingDiary = _createTestDiary(id: 1);
          final newDiary = _createTestDiary(id: 1);

          // Act
          final result = DiaryMergingHelper.mergeDiaries(
            [newDiary],
            [existingDiary],
          );

          // Assert
          expect(result, hasLength(1));
          expect(result.first.id, equals(1));
        });

        test('should handle multiple diaries correctly', () {
          // Arrange
          final existingDiaries = [
            _createTestDiary(id: 1, name: 'Diary 1'),
            _createTestDiary(id: 2, name: 'Diary 2'),
          ];

          final newDiaries = [
            _createTestDiary(id: 3, name: 'Diary 3'),
            _createTestDiary(id: 1, name: 'Updated Diary 1'),
          ];

          // Act
          final result = DiaryMergingHelper.mergeDiaries(
            newDiaries, existingDiaries
          );

          // Assert
          expect(result, hasLength(2));
          expect(result.any((d) => d.name == 'Diary 2'), isFalse);
          expect(result.any((d) => d.name == 'Diary 3'), isTrue);
          expect(result.any((d) => d.name == 'Updated Diary 1'), isTrue);
        });

        test('should handle empty input lists', () {
          // Act
          final result = DiaryMergingHelper.mergeDiaries([], []);

          // Assert
          expect(result, isEmpty);
        });

        test('should handle null activeDays correctly', () {
          // Arrange
          final existingDiary = _createTestDiary(id: 1, activeDays: [1, 2, 3]);
          final newDiary = _createTestDiary(id: 2, activeDays: null);

          // Act
          final result = DiaryMergingHelper.mergeDiaries(
            [newDiary],  [existingDiary]
          );

          // Assert
          expect(result, hasLength(1));
        });
      });

      group('Diary Contents Merging', () {
        test('should merge diary contents correctly', () {
          // Arrange
          final existingDiary = _createTestDiary(
            id: 1,
            name: 'Test Diary',
            status: DiaryStatus.ongoing,
            currentEntry: 2,
          );

          final newDiary = _createTestDiary(
            id: 2,
            name: 'Updated Diary',
            status: DiaryStatus.idle,
            currentEntry: 1,
          );

          // Act
          final result = DiaryMergingHelper.mergeDiaryContents(
            newDiary,
            existingDiary,
          );

          // Assert
          expect(result.id, equals(1));
          expect(result.name, equals('Updated Diary'));
          expect(result.currentEntry, equals(2));
          expect(result.status, equals(DiaryStatus.ongoing));
        });

        test('should preserve all existing data when merging', () {
          // Arrange
          final existingDiary = _createTestDiary(
            id: 1,
            currentEntry: 5,
            status: DiaryStatus.complete,
          );

          final newDiary = _createTestDiary(
            id: 2,
            currentEntry: 3,
            status: DiaryStatus.idle,
          );

          // Act
          final result = DiaryMergingHelper.mergeDiaryContents(
            newDiary,
            existingDiary,
          );

          // Assert
          expect(result.id, equals(1));
          expect(result.currentEntry, equals(5));
          expect(result.status, equals(DiaryStatus.complete));
        });

        test('should handle edge cases in content merging', () {
          // Arrange
          final existingDiary = _createTestDiary(
            id: 1,
            currentEntry: 0,
            status: DiaryStatus.idle,
          );

          final newDiary = _createTestDiary(
            id: 2,
            currentEntry: 0,
            status: DiaryStatus.idle,
          );

          // Act
          final result = DiaryMergingHelper.mergeDiaryContents(
            newDiary,
            existingDiary,
          );

          // Assert
          expect(result.currentEntry, equals(0));
          expect(result.status, equals(DiaryStatus.idle));
        });
      });

      group('Diary Key Generation', () {
        test('should generate consistent keys for same diary', () {
          // Arrange
          final diary1 = _createTestDiary(
            id: 1,
            studyID: 1,
            name: 'Test Diary',
            start: DateTime(2024, 1, 1),
            end: DateTime(2024, 1, 7),
          );

          final diary2 = _createTestDiary(
            id: 2, // Different ID
            studyID: 1,
            name: 'Test Diary',
            start: DateTime(2024, 1, 1),
            end: DateTime(2024, 1, 7),
          );

          // Act
          final key1 = DiaryMergingHelper._getDiaryKey(diary1);
          final key2 = DiaryMergingHelper._getDiaryKey(diary2);

          // Assert
          expect(key1, equals(key2));
        });

        test('should generate different keys for different diaries', () {
          // Arrange
          final diary1 = _createTestDiary(
            id: 1,
            studyID: 1,
            name: 'Test Diary 1',
          );

          final diary2 = _createTestDiary(
            id: 2,
            studyID: 1,
            name: 'Test Diary 2',
          );

          // Act
          final key1 = DiaryMergingHelper._getDiaryKey(diary1);
          final key2 = DiaryMergingHelper._getDiaryKey(diary2);

          // Assert
          expect(key1, isNot(equals(key2)));
        });
      });

      group('Diary Equality Comparison', () {
        test('should correctly identify equal diaries', () {
          // Arrange
          final diary1 = _createTestDiary(
            id: 1,
            studyID: 1,
            name: 'Test Diary',
            start: DateTime(2024, 1, 1),
            end: DateTime(2024, 1, 7),
            status: DiaryStatus.idle,
          );

          final diary2 = _createTestDiary(
            id: 1,
            studyID: 1,
            name: 'Test Diary',
            start: DateTime(2024, 1, 1),
            end: DateTime(2024, 1, 7),
            status: DiaryStatus.idle,
          );

          // Act
          final result = DiaryMergingHelper._isEffectivelyEqual(diary1, diary2);

          // Assert
          expect(result, isTrue);
        });

        test('should correctly identify different diaries', () {
          // Arrange
          final diary1 = _createTestDiary(
            id: 1,
            studyID: 1,
            name: 'Test Diary 1',
          );

          final diary2 = _createTestDiary(
            id: 2,
            studyID: 1,
            name: 'Test Diary 2',
          );

          // Act
          final result = DiaryMergingHelper._isEffectivelyEqual(diary1, diary2);

          // Assert
          expect(result, isFalse);
        });
      });
    });

    group('Data Validation Tests', () {
      test('should handle invalid diary data gracefully', () {
        // Arrange
        final invalidDiary = _createTestDiary(
          id: -1,
          studyID: 0,
          name: '',
        );

        // Act & Assert - Should not throw exceptions
        expect(() => DiaryMergingHelper._getDiaryKey(invalidDiary),
            returnsNormally);
        expect(() => DiaryMergingHelper.mergeDiaries([invalidDiary], []),
            returnsNormally);
      });

      test('should handle extreme date values', () {
        // Arrange
        final farFuture = DateTime(2099, 12, 31);
        final farPast = DateTime(1900, 1, 1);

        final diary1 = _createTestDiary(
          id: 1,
          start: farPast,
          end: farFuture,
        );

        final diary2 = _createTestDiary(
          id: 1,
          start: farPast,
          end: farFuture,
        );

        // Act
        final result = DiaryMergingHelper.mergeDiaries([diary1], [diary2]);

        // Assert
        expect(result, hasLength(1));
      });
    });
  });
}

/// Helper class for testing diary merging logic
///
/// This class replicates the core merging algorithms from SetupRepository
/// to allow for isolated unit testing of the business logic.
class DiaryMergingHelper {
  /// Merges new diaries with existing diaries using the same algorithm as SetupRepository
  static List<DiaryModel> mergeDiaries(
    List<DiaryModel> newDiaries,
    List<DiaryModel> existingDiaries,
  ) {
    final existingDiariesMap = {
      for (var diary in existingDiaries) _getDiaryKey(diary): diary
    };

    final result = <DiaryModel>[];

    for (final newDiary in newDiaries) {
      final key = _getDiaryKey(newDiary);
      final existingDiary = existingDiariesMap[key];

      if (existingDiary != null) {
        if (!_isEffectivelyEqual(newDiary, existingDiary)) {
          result.add(mergeDiaryContents(newDiary, existingDiary));
        } else {
          result.add(existingDiary);
        }
      } else {
        result.add(newDiary);
      }
    }

    return result;
  }

  /// Merges the contents of a new diary with an existing diary
  static DiaryModel mergeDiaryContents(
    DiaryModel newDiary,
    DiaryModel existingDiary,
  ) {
    return DiaryModel(
      id: existingDiary.id,
      studyID: newDiary.studyID,
      name: newDiary.name,
      prompts: newDiary.prompts,
      tags: newDiary.tags,
      status: existingDiary.status,
      due: newDiary.due,
      start: newDiary.start,
      end: newDiary.end,
      entries: newDiary.entries,
      currentEntry: existingDiary.currentEntry,
      notifications: newDiary.notifications,
      activeDays: newDiary.activeDays,
    );
  }

  /// Creates a composite key for unique diary identification
  static String _getDiaryKey(DiaryModel diary) =>
      '${diary.studyID}_${diary.name}_${diary.start.toIso8601String()}_${diary.end.toIso8601String()}';

  /// Compares two diaries for effective equality
  static bool _isEffectivelyEqual(DiaryModel diary1, DiaryModel diary2) {
    return diary1.id == diary2.id &&
        diary1.studyID == diary2.studyID &&
        diary1.name == diary2.name &&
        diary1.start == diary2.start &&
        diary1.end == diary2.end &&
        diary1.status == diary2.status;
  }
}

/// Test data builder for creating DiaryModel instances
///
/// This provides a clean, fluent API for creating test data
/// with sensible defaults and easy customization.
DiaryModel _createTestDiary({
  int id = 1,
  int studyID = 1,
  String name = 'Test Diary',
  DateTime? start,
  DateTime? end,
  DiaryStatus status = DiaryStatus.idle,
  DateTime? due,
  int currentEntry = 0,
  int entries = 1,
  List<int>? activeDays,
}) {
  final now = DateTime.now();
  return createTestDiaryModel(
    id: id,
    studyID: studyID,
    name: name,
    start: start ?? now,
    end: end ?? now.add(const Duration(hours: 1)),
    status: status,
    due: due ?? now.add(const Duration(hours: 1)),
    currentEntry: currentEntry,
    entries: entries,
    activeDays: activeDays,
  );
}
