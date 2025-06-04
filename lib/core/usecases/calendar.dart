import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';

Map<DateTime, List<String>> getCalendarEvents(List<DiaryModel> diaries) {
  final events = <DateTime, List<String>>{};

  for (final diary in diaries) {
    if (diary.activeDays == null || diary.activeDays!.isEmpty) {
      // Single event case - just use the start date
      final dateKey = normalizeDate(diary.start);
      final eventList = events.putIfAbsent(dateKey, () => []);
      if (eventList.isEmpty) {
        eventList.add(diary.start.toString());
      }
    } else {
      // Multiple active days case
      final start = diary.start;
      final end = diary.end;

      // Calculate the difference in days
      final daysDifference = end.difference(start).inDays;

      for (int i = 0; i <= daysDifference; i++) {
        final currentDate = start.add(Duration(days: i));

        // Check if this weekday is in active days
        if (diary.activeDays!.contains(currentDate.weekday) &&
            diary.status != DiaryStatus.submitted) {
          final dateKey = normalizeDate(currentDate);
          final eventList = events.putIfAbsent(dateKey, () => []);
          if (eventList.isEmpty) {
            eventList.add(diary.start.toString());
          }
        }
      }
    }
  }

  return events;
}

// Helper function to normalize date by removing time component
DateTime normalizeDate(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

List<DiaryModel> filterTodaysDiaries(
    DateTime date, List<DiaryModel> allDiaries) {
  return allDiaries.where((diary) {
    if (diary.activeDays?.isNotEmpty ?? false) {
      // Calculate date range between start and end
      final start = normalizeDate(diary.start);
      final end = normalizeDate(diary.end);
      final daysDifference = end.difference(start).inDays;

      // Find all active dates for this diary
      for (int i = 0; i <= daysDifference; i++) {
        final currentDate = start.add(Duration(days: i));
        if (diary.activeDays!.contains(currentDate.weekday) &&
            currentDate == normalizeDate(date)) {
          return true;
        }
      }
      // If diary has activeDays but none match the target date, return false
      // The addition of the return false; statement after the loop. This ensures that:
      // If a diary has activeDays and one of them matches the target date → return true
      // If a diary has activeDays but none match the target date → return false
      // If a diary has no activeDays → fall back to checking if the start date matches
      return false;
    }
    return normalizeDate(diary.start) == normalizeDate(date);
  }).toList();
}
