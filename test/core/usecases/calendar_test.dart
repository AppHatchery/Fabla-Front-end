import 'package:flutter_test/flutter_test.dart';
import 'package:audio_diaries_flutter/core/usecases/calendar.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';

void main() {
  group('getCalendarEvents', () {
    test('should handle single event diaries', () {
      // Arrange
      final diaries = [
        DiaryModel(
          id: 1,
          studyID: 1,
          name: 'Test Diary',
          start: DateTime(2024, 3, 15, 10, 0),
          end: DateTime(2024, 3, 15, 11, 0),
          activeDays: null,
          status: DiaryStatus.idle,
          due: DateTime(2024, 3, 15, 11, 0),
          entries: 1,
          currentEntry: 0,
          prompts: [],
          notifications: [],
          tags: null,
        ),
      ];

      // Act
      final events = getCalendarEvents(diaries);

      // Assert
      expect(events.length, 1);
      expect(events[DateTime(2024, 3, 15)], isNotNull);
      expect(events[DateTime(2024, 3, 15)]!.length, 1);
      expect(events[DateTime(2024, 3, 15)]!.first,
          equals(diaries[0].start.toString()));
    });

    test('should handle multiple active days diaries', () {
      // Arrange
      final diaries = [
        DiaryModel(
          id: 1,
          studyID: 1,
          name: 'Test Diary',
          start: DateTime(2024, 3, 15, 10, 0),
          end: DateTime(2024, 3, 17, 11, 0),
          activeDays: [5, 6, 7], // Friday, Saturday, Sunday
          status: DiaryStatus.idle,
          due: DateTime(2024, 3, 17, 11, 0),
          entries: 1,
          currentEntry: 0,
          prompts: [],
          notifications: [],
          tags: null,
        ),
      ];

      // Act
      final events = getCalendarEvents(diaries);

      // Assert
      expect(events.length, 3);
      expect(events[DateTime(2024, 3, 15)], isNotNull); // Friday
      expect(events[DateTime(2024, 3, 16)], isNotNull); // Saturday
      expect(events[DateTime(2024, 3, 17)], isNotNull); // Sunday
      expect(events[DateTime(2024, 3, 15)]!.length, 1);
      expect(events[DateTime(2024, 3, 16)]!.length, 1);
      expect(events[DateTime(2024, 3, 17)]!.length, 1);
    });

    test('should not include submitted diaries in active days', () {
      // Arrange
      final diaries = [
        DiaryModel(
          id: 1,
          studyID: 1,
          name: 'Test Diary',
          start: DateTime(2024, 3, 15, 10, 0),
          end: DateTime(2024, 3, 17, 11, 0),
          activeDays: [5, 6, 7], // Friday, Saturday, Sunday
          status: DiaryStatus.submitted,
          due: DateTime(2024, 3, 17, 11, 0),
          entries: 1,
          currentEntry: 0,
          prompts: [],
          notifications: [],
          tags: null,
        ),
      ];

      // Act
      final events = getCalendarEvents(diaries);

      // Assert
      expect(events.length, 0);
    });

    test('should handle multiple diaries on the same day', () {
      // Arrange
      final diaries = [
        DiaryModel(
          id: 1,
          studyID: 1,
          name: 'Test Diary 1',
          start: DateTime(2024, 3, 15, 10, 0),
          end: DateTime(2024, 3, 15, 11, 0),
          activeDays: null,
          status: DiaryStatus.idle,
          due: DateTime(2024, 3, 15, 11, 0),
          entries: 1,
          currentEntry: 0,
          prompts: [],
          notifications: [],
          tags: null,
        ),
        DiaryModel(
          id: 2,
          studyID: 1,
          name: 'Test Diary 2',
          start: DateTime(2024, 3, 15, 14, 0),
          end: DateTime(2024, 3, 15, 15, 0),
          activeDays: null,
          status: DiaryStatus.idle,
          due: DateTime(2024, 3, 15, 15, 0),
          entries: 1,
          currentEntry: 0,
          prompts: [],
          notifications: [],
          tags: null,
        ),
      ];

      // Act
      final events = getCalendarEvents(diaries);

      // Assert
      expect(events.length, 1);
      expect(events[DateTime(2024, 3, 15)]!.length, 1);
      expect(events[DateTime(2024, 3, 15)]!.first,
          equals(diaries[0].start.toString()));
    });
  });

  group('normalizeDate', () {
    test('should remove time component from DateTime', () {
      // Arrange
      final dateTime = DateTime(2024, 3, 15, 10, 30, 45);

      // Act
      final normalized = normalizeDate(dateTime);

      // Assert
      expect(normalized, equals(DateTime(2024, 3, 15)));
    });
  });

  group('filterTodaysDiaries', () {
    test('should filter single event diaries for today', () {
      // Arrange
      final today = DateTime(2024, 3, 15);
      final diaries = [
        DiaryModel(
          id: 1,
          studyID: 1,
          name: 'Test Diary 1',
          start: DateTime(2024, 3, 15, 10, 0),
          end: DateTime(2024, 3, 15, 11, 0),
          activeDays: null,
          status: DiaryStatus.idle,
          due: DateTime(2024, 3, 15, 11, 0),
          entries: 1,
          currentEntry: 0,
          prompts: [],
          notifications: [],
          tags: null,
        ),
        DiaryModel(
          id: 2,
          studyID: 1,
          name: 'Test Diary 2',
          start: DateTime(2024, 3, 16, 10, 0),
          end: DateTime(2024, 3, 16, 11, 0),
          activeDays: null,
          status: DiaryStatus.idle,
          due: DateTime(2024, 3, 16, 11, 0),
          entries: 1,
          currentEntry: 0,
          prompts: [],
          notifications: [],
          tags: null,
        ),
      ];

      // Act
      final filtered = filterTodaysDiaries(today, diaries);

      // Assert
      expect(filtered.length, 1);
      expect(filtered.first.id, equals(1));
    });

    test('should filter multiple active days diaries for today', () {
      // Arrange
      final today = DateTime(2024, 3, 15); // Friday
      final diaries = [
        DiaryModel(
          id: 1,
          studyID: 1,
          name: 'Test Diary 1',
          start: DateTime(2024, 3, 15, 10, 0),
          end: DateTime(2024, 3, 17, 11, 0),
          activeDays: [5, 6, 7], // Friday, Saturday, Sunday
          status: DiaryStatus.idle,
          due: DateTime(2024, 3, 17, 11, 0),
          entries: 1,
          currentEntry: 0,
          prompts: [],
          notifications: [],
          tags: null,
        ),
        DiaryModel(
          id: 2,
          studyID: 1,
          name: 'Test Diary 2',
          start: DateTime(2024, 3, 16, 10, 0),
          end: DateTime(2024, 3, 17, 11, 0),
          activeDays: [6, 7], // Saturday, Sunday
          status: DiaryStatus.idle,
          due: DateTime(2024, 3, 17, 11, 0),
          entries: 1,
          currentEntry: 0,
          prompts: [],
          notifications: [],
          tags: null,
        ),
      ];

      // Act
      final filtered = filterTodaysDiaries(today, diaries);

      // Assert
      expect(filtered.length, 1);
      expect(filtered.first.id, equals(1));
    });

    test('should not include diaries with no matching active days', () {
      // Arrange
      final today = DateTime(2024, 3, 15); // Friday
      final diaries = [
        DiaryModel(
          id: 1,
          studyID: 1,
          name: 'Test Diary',
          start: DateTime(2024, 3, 15, 10, 0),
          end: DateTime(2024, 3, 17, 11, 0),
          activeDays: [6, 7], // Saturday, Sunday
          status: DiaryStatus.idle,
          due: DateTime(2024, 3, 17, 11, 0),
          entries: 1,
          currentEntry: 0,
          prompts: [],
          notifications: [],
          tags: null,
        ),
      ];

      // Act
      final filtered = filterTodaysDiaries(today, diaries);

      // Assert
      expect(filtered.length, 0);
    });
  });
}
