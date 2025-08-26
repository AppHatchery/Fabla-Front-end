import 'package:flutter_test/flutter_test.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';

void main() {
  group('Formatter Tests', () {
    test('twoDigits should pad single digit numbers with leading zero', () {
      expect(twoDigits(5), equals('05'));
      expect(twoDigits(10), equals('10'));
      expect(twoDigits(0), equals('00'));
    });

    test('formatDate should format DateTime correctly', () {
      final date = DateTime(2024, 3, 15, 14, 30, 45);
      expect(formatDate(date), equals('2024-03-15-14-30-45'));
    });

    test('formatDateShort should format time correctly', () {
      final date = DateTime(2024, 3, 15, 14, 30);
      expect(formatDateShort(date), contains('2:30'));
      expect(formatDateShort(date), contains('PM'));
    });

    test('formatDateOnly should format date without time', () {
      final date = DateTime(2024, 3, 15);
      expect(formatDateOnly(date), equals('2024-03-15'));
    });

    test('stringDateOnlyToDateTime should parse date string correctly', () {
      final dateStr = '2024-03-15';
      final expected = DateTime(2024, 3, 15, 0, 0, 0, 0);
      expect(stringDateOnlyToDateTime(dateStr), equals(expected));
    });

    test('formatDuration should format milliseconds correctly', () {
      expect(formatDuration(3661000),
          equals('01:01:01')); // 1 hour, 1 minute, 1 second
      expect(formatDuration(61000), equals('01:01')); // 1 minute, 1 second
      expect(formatDuration(1000), equals('00:01')); // 1 second
    });

    test('formatDurationtoHHMMSS should format duration correctly', () {
      final duration = Duration(hours: 1, minutes: 2, seconds: 3);
      expect(formatDurationtoHHMMSS(duration), equals('02:03'));
    });

    test('formatDurationToHHMM should format time correctly', () {
      final date = DateTime(2024, 3, 15, 14, 30);
      expect(formatDurationToHHMM(date), equals('14:30'));
    });

    test('formatDurationToHHMMPP should format time with AM/PM', () {
      final date = DateTime(2024, 3, 15, 14, 30);
      expect(formatDurationToHHMMPP(date), equals('02:30 PM'));
    });

    test('formatStringToDuration should parse time string correctly', () {
      final timeStr = '01:30:45';
      final expected = Duration(hours: 1, minutes: 30, seconds: 45);
      expect(formatStringToDuration(timeStr), equals(expected));
    });

    test('formatDurationMMOnly should return only minutes', () {
      final duration = Duration(hours: 1, minutes: 5, seconds: 30);
      expect(formatDurationMMOnly(duration), equals('05'));
    });

    test('formatDurationSSOnly should return only seconds', () {
      final duration = Duration(minutes: 1, seconds: 5);
      expect(formatDurationSSOnly(duration), equals('05'));
    });

    test('formatDurationToString should format duration correctly', () {
      final duration = Duration(hours: 1, minutes: 2, seconds: 3);
      expect(formatDurationToString(duration), equals('01:02:03'));
    });

    test('formatDiaryCardDue should format due date correctly', () {
      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 1));
      final due = now.add(const Duration(hours: 2));

      // Test submitted status
      expect(
        formatDiaryCardDue(due, start, DiaryStatus.submitted),
        equals('Submitted'),
      );

      // Test future start time
      final futureStart = now.add(const Duration(hours: 1));
      expect(
        formatDiaryCardDue(due, futureStart, DiaryStatus.idle),
        startsWith('Opens at:'),
      );

      // Test past due date
      final pastDue = now.subtract(const Duration(days: 2));
      expect(
        formatDiaryCardDue(pastDue, start, DiaryStatus.idle),
        startsWith('Closed on:'),
      );
    });

    test('formatDiaryCardDueColors should return correct colors', () {
      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 1));
      final due = now.add(const Duration(hours: 2));
      final optional = true;

      // Test submitted status
      final submittedColors =
          formatDiaryCardDueColors(due, start, DiaryStatus.submitted, optional);
      expect(submittedColors[0], equals(CustomColors.darkGreen));
      expect(submittedColors[1], equals(CustomColors.textWhite));

      // Test future start time
      final futureStart = now.add(const Duration(hours: 1));
      final futureColors =
          formatDiaryCardDueColors(due, futureStart, DiaryStatus.idle, optional);
      expect(futureColors[0], equals(CustomColors.fillDisabled));
      expect(futureColors[1], equals(CustomColors.midGrey));
    });

    test('formatHistoryDate should format date correctly', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 14, 30);
      final yesterday = today.subtract(const Duration(days: 1));
      final pastDate = today.subtract(const Duration(days: 5));

      expect(formatHistoryDate(today), startsWith('Today -'));
      expect(formatHistoryDate(yesterday), startsWith('Yesterday -'));
      expect(formatHistoryDate(pastDate), contains(' - '));
    });
  });
}
