import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';

final allMediaTypes = [
  ResponseType.audio,
  ResponseType.textAudio,
  ResponseType.image,
  ResponseType.video,
  ResponseType.imageVideo
];
final diaryRepository = DiaryRepository();

String determineDiaryIcon(DiaryModel diary) {
  final responseTypes = diary.prompts
      .where((p) => p.responseType != null)
      .map((p) => p.responseType!)
      .toSet();

  final hasAudio = responseTypes.contains(ResponseType.audio) ||
      responseTypes.contains(ResponseType.textAudio);

  final hasCamera = responseTypes.contains(ResponseType.image) ||
      responseTypes.contains(ResponseType.video) ||
      responseTypes.contains(ResponseType.imageVideo);

  final hasTimer = responseTypes.contains(ResponseType.timer);

  // Doesn’t have audio/video/timer questions
  if (!hasAudio && !hasCamera && !hasTimer) {
    return "assets/images/icons/survey.png";
  }

  // has audio question(s), doesn’t have video/timer questions.
  // if (hasAudio && !hasCamera && !hasTimer) {
  //   return "assets/images/icons/survey.png";
  // }

  // has question(s) requires camera usage, doesn’t have audio/timer questions.
  if (hasCamera && !hasAudio && !hasTimer) {
    return "assets/images/icons/camera.png";
  }

  // has timer question(s), doesn’t have video/audio questions.
  if (hasTimer && !hasAudio && !hasCamera) {
    return "assets/images/icons/timer.png";
  }

  return "assets/images/icons/mic.png";
}

/// Asynchronous method to load and organize Diary objects for display on the home screen.
/// This function initiates the loading process of Diary objects and their organization for display on the home screen.
///
/// Order:
/// 1.  first due comes first
/// 2. if there are more than one entries due at the same time, display the new ones on top.
/// 3. if there are more than one entries due at the same time and opens at the same time, display in orders of: audio diary, survey diary, video diary, timer diary
List<DiaryModel> prioritySort(List<DiaryModel> diaries) {
  final now = DateTime.now();

  return List<DiaryModel>.from(diaries)
    ..sort((a, b) {
      // Determine priority category for each diary (0=high, 1=medium, 2=low)
      final aPriority = getPriorityCategory(a, now);
      final bPriority = getPriorityCategory(b, now);

      // If different categories, sort by category
      if (aPriority != bPriority) {
        return aPriority - bPriority;
      }

      if (aPriority == 0) {
        // High priority: sort by due date
        return a.due.compareTo(b.due);
      } else {
        // Medium and low: sort by start date
        return a.start.compareTo(b.start);
      }
    });
}

// Helper method for _prioritySort to determine priority category
int getPriorityCategory(DiaryModel diary, DateTime now) {
  if (diary.start.isBefore(now) && diary.due.isAfter(now)) {
    return 0; // High priority
  } else if (diary.start.isAfter(now) && diary.due.isAfter(now)) {
    return 1; // Medium priority
  } else {
    return 2; // Low priority
  }
}

// Retrieves diaries that should be available on the homepage for a specific day.
///
/// This function returns diaries that:
/// - Are available on the specified day (typically today)
/// - Started on or before the specified day and due on or after the specified day
/// - Respect active days constraints (weekly diaries only show on their active days)
/// - Are not already submitted or missed
/// - Are not past their due date
///
/// Parameters:
/// - [day]: The day to get diaries for (typically DateTime.now() for homepage)
///
/// Returns:
/// A list of DiaryModel objects that should be available on the specified day
List<DiaryModel> getDiariesUseCase(
  List<Diary> diaries,
  DateTime day,
) {
  // Create shifted day boundaries (04:00 - 03:59)
  final shiftedDayBoundaries = _getShiftedDayBoundaries(day);
  final dayStart = shiftedDayBoundaries.start;
  final dayEnd = shiftedDayBoundaries.end;
  final now = DateTime.now();

  // Filter diaries that should be available on the specified day
  final availableDiaries = diaries.where((diary) {
    return _isDiaryAvailableOnDay(diary, day, dayStart, dayEnd, now);
  }).toList();

  // Convert entities to models and return
  return availableDiaries
      .map((entity) => DiaryModel.fromEntity(entity))
      .toList();
}

/// Determines if a diary should be available on the specified day
bool _isDiaryAvailableOnDay(Diary diary, DateTime targetDay, DateTime dayStart,
    DateTime dayEnd, DateTime now) {
  // RULE 1: Diary must have started by the target day
  if (diary.start.isAfter(dayEnd)) {
    return false;
  }

  // RULE 2: Diary must not be past its due date
  if (diary.due.isBefore(now)) {
    return false;
  }

  // RULE 3: Diary must be due on or after the target day
  if (diary.due.isBefore(dayStart)) {
    return false;
  }

  // RULE 4: ~~Exclude already submitted diaries~~ | Including submitted diaries for daily goal
  if (diary.status == DiaryStatus.submitted) {
    return true;
  }

  // RULE 5: Exclude missed diaries
  if (diary.status == DiaryStatus.missed) {
    return false;
  }

  // RULE 6: Check active days constraint for weekly diaries
  if (diary.activeDays != null && diary.activeDays!.isNotEmpty) {
    return _isDiaryActiveOnDay(diary, targetDay);
  }

  // RULE 7: For daily diaries (no active days), check if it's within the active period
  return _isDailyDiaryAvailable(diary, dayStart, dayEnd);
}

/// Checks if a weekly diary (with active days) should be active on the target day
bool _isDiaryActiveOnDay(Diary diary, DateTime targetDay) {
  // Check if the target day's weekday is in the diary's active days
  // DateTime.weekday: Monday = 1, Tuesday = 2, ..., Sunday = 7
  final targetWeekday = targetDay.weekday;

  return diary.activeDays!.contains(targetWeekday);
}

/// Checks if a daily diary (no active days) should be available on the target day
bool _isDailyDiaryAvailable(Diary diary, DateTime dayStart, DateTime dayEnd) {
  // For daily diaries, they're available if:
  // 1. They started before or during the target day AND
  // 2. They're due after or during the target day

  final startsBeforeOrDuringDay = diary.start.isBefore(dayEnd);
  final dueAfterOrDuringDay = diary.due.isAfter(dayStart);

  return startsBeforeOrDuringDay && dueAfterOrDuringDay;
}

/// Data class to hold shifted day boundaries
class ShiftedDayBoundaries {
  final DateTime start;
  final DateTime end;

  ShiftedDayBoundaries({required this.start, required this.end});
}

/// Calculates the shifted day boundaries (04:00 - 03:59) for a given day
ShiftedDayBoundaries _getShiftedDayBoundaries(DateTime day) {
  // For shifted days (04:00 - 03:59), we need to determine which 24-hour period
  // the current time falls into

  DateTime baseDate;

  if (day.hour >= 4) {
    // If it's 4 AM or later, the shifted day starts today at 4 AM
    baseDate = DateTime(day.year, day.month, day.day);
  } else {
    // If it's before 4 AM, the shifted day started yesterday at 4 AM
    baseDate = DateTime(day.year, day.month, day.day)
        .subtract(const Duration(days: 1));
  }

  final dayStart =
      DateTime(baseDate.year, baseDate.month, baseDate.day, 4, 0, 0);
  final dayEnd = dayStart
      .add(const Duration(days: 1))
      .subtract(const Duration(milliseconds: 1));

  return ShiftedDayBoundaries(start: dayStart, end: dayEnd);
}

/// Determines the logical day for active days calculation
/// This is the day that users would conceptually think of
// DateTime _getLogicalDay(DateTime currentTime) {
//   // If it's before 4 AM, users still think of it as "yesterday"
//   if (currentTime.hour < 4) {
//     return DateTime(currentTime.year, currentTime.month, currentTime.day)
//         .subtract(const Duration(days: 1));
//   }

//   // If it's 4 AM or later, it's the current calendar day
//   return DateTime(currentTime.year, currentTime.month, currentTime.day);
// }
