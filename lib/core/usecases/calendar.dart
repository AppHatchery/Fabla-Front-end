import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';

Map<DateTime, List<String>> getCalendarEvents(List<DiaryModel> diaries) {
  final events = <DateTime, List<String>>{};

  for (final diary in diaries) {
    if (diary.activeDays == null || diary.activeDays!.isEmpty) {
      // Single event case - just use the start date
      final dateKey = _normalizeDate(diary.start);
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
          final dateKey = _normalizeDate(currentDate);
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
DateTime _normalizeDate(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

List<DiaryModel> filterTodaysDiaries(
    DateTime date, List<DiaryModel> allDiaries) {
  return allDiaries.where((diary) {
    if (diary.activeDays?.isNotEmpty ?? false) {
      // Calculate date range between start and end
      final start = _normalizeDate(diary.start);
      final end = _normalizeDate(diary.end);
      final daysDifference = end.difference(start).inDays;

      // Find all active dates for this diary
      for (int i = 0; i <= daysDifference; i++) {
        final currentDate = start.add(Duration(days: i));
        if (diary.activeDays!.contains(currentDate.weekday) &&
            currentDate == _normalizeDate(date)) {
          return true;
        }
      }
    }
    return _normalizeDate(diary.start) == _normalizeDate(date);
  }).toList();
}
