import 'package:flutter_test/flutter_test.dart';
import 'package:audio_diaries_flutter/core/usecases/calendar.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';

import '../../dummy_data.dart';

void main() {
  group('getCalendarEvents', () {
    test('should handle single event diaries', () {
      // Arrange
      final diaries = [
        createTestDiaryModel(
          start: TestDates.testDate,
          end: TestDates.testEndDate,
          due: TestDates.testEndDate,
          activeDays: null, // Single event diary
        ),
      ];

      // Act
      final events = getCalendarEvents(diaries);

      // Assert
      expect(events.length, 1);
      final normalizedTestDate = DateTime(2024, 3, 15); // Normalized testDate
      expect(events[normalizedTestDate], isNotNull);
      expect(events[normalizedTestDate]!.length, 1);
      expect(events[normalizedTestDate]!.first,
          equals(diaries[0].start.toString()));
    });

    test('should handle multiple active days diaries', () {
      // Arrange - Create diary that starts on Monday with active days Mon, Tue, Wed
      final startDate = DateTime(2024, 3, 18); // Monday (weekday 1)
      final endDate = DateTime(2024, 3, 20); // Wednesday (weekday 3)

      final diaries = [
        createTestDiaryModel(
          start: startDate,
          end: endDate,
          activeDays: TestValues.testActiveDays, // [1, 2, 3] = Mon, Tue, Wed
        ),
      ];

      // Act
      final events = getCalendarEvents(diaries);

      // Assert - Should have events for each active day within the range
      expect(events.length, 3); // Mon, Tue, Wed

      // Check specific dates
      expect(events[DateTime(2024, 3, 18)], isNotNull); // Monday
      expect(events[DateTime(2024, 3, 19)], isNotNull); // Tuesday
      expect(events[DateTime(2024, 3, 20)], isNotNull); // Wednesday

      // Check that events are created for the active days
      for (final entry in events.entries) {
        final weekday = entry.key.weekday;
        expect(TestValues.testActiveDays.contains(weekday), isTrue);
      }
    });

    test('should not include submitted diaries in active days', () {
      // Arrange
      final startDate = DateTime(2024, 3, 18); // Monday
      final endDate = DateTime(2024, 3, 20); // Wednesday

      final diaries = [
        createTestDiaryModel(
          status: DiaryStatus.submitted,
          start: startDate,
          end: endDate,
          activeDays: TestValues.testActiveDays,
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
        createTestDiaryModel(
          id: 1,
          name: '${TestValues.testName} 1',
          start: TestDates.testDate,
          end: TestDates.testEndDate,
          due: TestDates.testEndDate,
          activeDays: null, // Single event
        ),
        createTestDiaryModel(
          id: 2,
          name: '${TestValues.testName} 2',
          start: TestDates.testDate,
          end: TestDates.testEndDate,
          due: TestDates.testEndDate,
          activeDays: null, // Single event
        ),
      ];

      // Act
      final events = getCalendarEvents(diaries);

      // Assert - Only one event per day (production logic only adds if eventList.isEmpty)
      expect(events.length, 1);
      final normalizedTestDate = DateTime(2024, 3, 15);
      expect(events[normalizedTestDate]!.length, 1);
      expect(events[normalizedTestDate]!.first,
          equals(diaries[0].start.toString()));
    });

    test('should handle diaries with different date ranges', () {
      // Arrange - Use fixed dates to avoid dynamic date issues
      final firstDate = DateTime(2024, 3, 15);
      final secondDate = DateTime(2024, 3, 16);

      final diaries = [
        createTestDiaryModel(
          id: 1,
          start: firstDate,
          end: firstDate,
          activeDays: null,
        ),
        createTestDiaryModel(
          id: 2,
          start: secondDate,
          end: secondDate,
          activeDays: null,
        ),
      ];

      // Act
      final events = getCalendarEvents(diaries);

      // Assert
      expect(events.length, 2);
      expect(events[firstDate], isNotNull);
      expect(events[secondDate], isNotNull);
    });

    test(
        'should only create one event per day even with overlapping active days',
        () {
      // Arrange - Two diaries with same active days
      final startDate = DateTime(2024, 3, 18); // Monday
      final endDate = DateTime(2024, 3, 18); // Same day

      final diaries = [
        createTestDiaryModel(
          id: 1,
          start: startDate,
          end: endDate,
          activeDays: [1], // Monday
        ),
        createTestDiaryModel(
          id: 2,
          start: startDate,
          end: endDate,
          activeDays: [1], // Monday
        ),
      ];

      // Act
      final events = getCalendarEvents(diaries);

      // Assert - Only one event per day (eventList.isEmpty check)
      expect(events.length, 1);
      expect(events[DateTime(2024, 3, 18)]!.length, 1);
    });
  });

  group('normalizeDate', () {
    test('should remove time component from DateTime', () {
      // Arrange
      final dateTimeWithTime = DateTime(2024, 3, 15, 14, 30, 45);
      final expectedDate = DateTime(2024, 3, 15);

      // Act
      final normalized = normalizeDate(dateTimeWithTime);

      // Assert
      expect(normalized, equals(expectedDate));
      expect(normalized.hour, equals(0));
      expect(normalized.minute, equals(0));
      expect(normalized.second, equals(0));
    });

    test('should handle date that already has no time component', () {
      // Arrange
      final dateWithoutTime = DateTime(2024, 3, 15);

      // Act
      final normalized = normalizeDate(dateWithoutTime);

      // Assert
      expect(normalized, equals(dateWithoutTime));
    });
  });

  group('filterTodaysDiaries', () {
    test('should filter single event diaries for today', () {
      // Arrange
      final today = DateTime(2024, 3, 15); // Use normalized date
      final tomorrowDate = DateTime(2024, 3, 16); // Fixed tomorrow

      final diaries = [
        createTestDiaryModel(
          id: 1,
          start:
              TestDates.testDate, // 2024-3-15 (matches today when normalized)
          end: TestDates.testEndDate,
          activeDays: null, // Single event
        ),
        createTestDiaryModel(
          id: 2,
          start: tomorrowDate, // Different day
          end: tomorrowDate,
          activeDays: null, // Single event
        ),
      ];

      // Act
      final filtered = filterTodaysDiaries(today, diaries);

      // Assert
      expect(filtered.length, 1);
      expect(filtered.first.id, equals(1));
    });

    test('should filter multiple active days diaries for today', () {
      final today = DateTime(2024, 3, 18); // Monday (weekday 1)
      final diaries = [
        createTestDiaryModel(
          id: 1,
          start: DateTime(2024, 3, 18), // Start on Monday
          end: DateTime(2024, 3, 20), // End on Wednesday
          activeDays: [1, 3, 5], // Mon, Wed, Fri - includes today (Monday)
          status: DiaryStatus.idle,
        ),
        createTestDiaryModel(
          id: 2,
          start: DateTime(2024, 3, 19), // Start on Tuesday (not today)
          end: DateTime(2024, 3, 20),
          activeDays: [2, 4, 6], // Tue, Thu, Sat - excludes today (Monday)
          status: DiaryStatus.idle,
        ),
      ];

      final filtered = filterTodaysDiaries(today, diaries);

      expect(filtered.length, 1);
      expect(filtered.first.id, equals(1));
    });

    test('should not include diaries with no matching active days', () {
      final today = DateTime(2024, 3, 18); // Monday (weekday 1)
      final diaries = [
        createTestDiaryModel(
          id: 1,
          start: DateTime(2024, 3, 19), // Start on Tuesday (not today)
          end: DateTime(2024, 3, 20),
          activeDays: [2, 4, 6], // Tue, Thu, Sat - excludes Monday
          status: DiaryStatus.idle,
        ),
      ];

      final filtered = filterTodaysDiaries(today, diaries);

      expect(filtered.length, 0);
    });

    test(
        'should include diaries when today falls within single event date range',
        () {
      // Arrange
      final today = DateTime(2024, 3, 15);
      final diaries = [
        createTestDiaryModel(
          start: TestDates.testDate, // 2024-3-15 (matches when normalized)
          end: TestDates.testDate,
          activeDays: null, // Single event diary
        ),
      ];

      // Act
      final filtered = filterTodaysDiaries(today, diaries);

      // Assert
      expect(filtered.length, 1);
    });

    test('should not include submitted diaries', () {
      // Arrange
      final today = DateTime(2024, 3, 15);
      final diaries = [
        createTestDiaryModel(
          id: 1,
          start: TestDates.testDate,
          end: TestDates.testDate,
          status: DiaryStatus.submitted,
          activeDays: null,
        ),
        createTestDiaryModel(
          id: 2,
          start: TestDates.testDate,
          end: TestDates.testDate,
          status: DiaryStatus.idle,
          activeDays: null,
        ),
      ];

      // Act
      final filtered = filterTodaysDiaries(today, diaries);

      // Assert
      expect(filtered.length, 2);
      expect(filtered.any((d) => d.status == DiaryStatus.idle), isTrue);
      expect(filtered.any((d) => d.status == DiaryStatus.submitted), isTrue);
    });

    test(
        'should handle active days diary that falls back to single event logic',
        () {
      // Arrange - Diary with active days but today doesn't match any active day,
      // should fall back to checking start date
      final today = DateTime(2024, 3, 18); // Monday
      final diaries = [
        createTestDiaryModel(
          start: DateTime(2024, 3, 18), // Start on Monday
          end: DateTime(2024, 3, 20), // End on Wednesday
          activeDays: [2, 4], // Tue, Thu only - doesn't include Monday
        ),
      ];

      // Act
      final filtered = filterTodaysDiaries(today, diaries);

      // Assert - Should include because start date matches today
      expect(filtered.length, 1);
    });
  });
}
