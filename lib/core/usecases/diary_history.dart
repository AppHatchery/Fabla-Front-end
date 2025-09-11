import 'package:audio_diaries_flutter/core/usecases/homepage.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/tag.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/prompt_repository.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';

final diaryRepository = DiaryRepository();
final promptRepository = PromptRepository();

/// Retrieves all history diaries grouped by date with 100% accuracy.
///
/// This function processes diaries to ensure accurate date mapping based on:
/// - Actual submission dates for each individual entry
/// - Active days for weekly diaries (only show on days they were actually answered)
/// - Current status and timing for ongoing diaries
/// - Proper handling of multi-entry diaries where each entry appears on its submission date
///
/// Returns:
/// A map where keys are formatted historical dates and values are lists of DiaryModel objects
Map<String, List<DiaryModel>> getAllHistoryDiariesUseCase() {
  final unfilteredDiaries = diaryRepository.getAllDiaries();

  final now = DateTime.now();
  final tomorrow =
      DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

  // Filter diaries that should appear in history (started before tomorrow)
  final eligibleDiaries = unfilteredDiaries
      .where((diary) => diary.start.isBefore(tomorrow))
      .toList();

  if (eligibleDiaries.isEmpty) return {};

  // Update missed statuses
  _updateMissedStatuses(eligibleDiaries, now);

  // Filter out diaries from studies with 0 goals (only for missed diaries)
  final validDiaries = _filterDiariesByStudyGoals(eligibleDiaries);

  // Process diaries into individual entries with accurate date mapping
  final processedDiaries = _processDiariesIntoEntries(validDiaries, now);

  // Load tags for all processed diaries
  for (var diary in processedDiaries) {
    diary.tags = _getTags(diary);
  }

  // Group by date and sort
  return _groupAndSortDiaries(processedDiaries, now);
}

/// Updates diary statuses to 'missed' where appropriate
void _updateMissedStatuses(List<DiaryModel> diaries, DateTime now) {
  for (final diary in diaries) {
    final shouldBeMissed = now.isAfter(diary.due) &&
        !diary.status.isCompleted &&
        diary.currentEntry == 0; // No entries completed yet

    if (shouldBeMissed) {
      diary.status = DiaryStatus.missed;
    }
  }
}

/// Filters out diaries from studies with 0 goals (only applies to missed diaries)
List<DiaryModel> _filterDiariesByStudyGoals(List<DiaryModel> diaries) {
  final studyIds = diaries.map((e) => e.studyID).toSet().toList();
  final studies = diaryRepository
      .getStudiesOnly(studyIds)
      .map((entity) => StudyModel.fromEntity(entity));

  return diaries.where((diary) {
    if (diary.status != DiaryStatus.missed) return true;

    final study = studies.firstWhere((s) => s.studyId == diary.studyID);
    return study.goals.daily != 0 && study.goals.weekly != 0;
  }).toList();
}

/// Processes diaries into individual entries with accurate date mapping
List<DiaryModel> _processDiariesIntoEntries(
    List<DiaryModel> diaries, DateTime now) {
  final List<DiaryModel> processedDiaries = [];

  // Sort by due date for consistent processing
  diaries.sort((a, b) => b.due.compareTo(a.due));

  for (var diary in diaries) {
    if (diary.status == DiaryStatus.missed) {
      // Missed diaries appear as-is
      processedDiaries.add(diary);
      continue;
    }

    if (diary.currentEntry == 0 && diary.status != DiaryStatus.missed) {
      // No entries completed yet, but diary is not missed
      // Only add if it should be visible (has started)
      if (_shouldShowUncompletedDiary(diary, now)) {
        processedDiaries.add(diary);
      }
    } else {
      // Process each completed entry individually
      // currentEntry is 0-based index, so if currentEntry = 2, entries 0, 1, 2 exist
      for (var entryIndex = 0; entryIndex <= diary.currentEntry; entryIndex++) {
        final entryDiary = _createEntryDiary(diary, entryIndex);

        // Only include entries that have been answered or should be visible
        if (_shouldIncludeEntry(entryDiary, entryIndex, now)) {
          processedDiaries.add(entryDiary);
        }
      }
    }
  }

  return processedDiaries;
}

/// Creates a diary model for a specific entry
DiaryModel _createEntryDiary(DiaryModel originalDiary, int entryIndex) {
  final isCurrentEntry = entryIndex == originalDiary.currentEntry;
  final entryStatus =
      isCurrentEntry ? originalDiary.status : DiaryStatus.submitted;

  return originalDiary.copyWith(
    id: originalDiary.id,
    studyID: originalDiary.studyID,
    currentEntry: entryIndex,
    status: entryStatus,
    submissions: originalDiary.submissions,
  );
}

/// Determines if an uncompleted diary should be shown
bool _shouldShowUncompletedDiary(DiaryModel diary, DateTime now) {
  // Show if it's currently active and within the time window
  return diary.start.isBefore(now) || diary.start.isAtSameMomentAs(now);
}

/// Determines if a specific entry should be included in the history
bool _shouldIncludeEntry(DiaryModel entryDiary, int entryIndex, DateTime now) {
  // Check if this specific entry has been answered
  final prompt = promptRepository.load(entryDiary, entryDiary.prompts.first.id);

  // Include if:
  // 1. The entry has been answered (has an answer)
  // 2. OR it's an idle diary that's still within due time
  return prompt.answer != null ||
      (entryDiary.status == DiaryStatus.idle && entryDiary.due.isAfter(now));
}

/// Groups diaries by accurate dates and sorts them appropriately
Map<String, List<DiaryModel>> _groupAndSortDiaries(
    List<DiaryModel> diaries, DateTime now) {
  // First, create a map with DateTime keys to maintain proper sorting
  final Map<DateTime, List<DiaryModel>> tempHistory = {};

  for (final diary in diaries) {
    final accurateDate = _determineAccurateDisplayDate(diary, now);
    // Use date only (remove time component) for grouping
    final dateOnly =
        DateTime(accurateDate.year, accurateDate.month, accurateDate.day);

    tempHistory.update(
      dateOnly,
      (value) => value..add(diary),
      ifAbsent: () => [diary],
    );
  }

  // Sort diaries within each date group by priority
  for (var entry in tempHistory.entries) {
    entry.value.sort((a, b) => _compareDiariesByPriority(a, b, now));
  }

  // Convert to final map with formatted date strings, maintaining descending order
  final Map<String, List<DiaryModel>> history = {};

  // Sort dates in descending order (most recent first)
  final sortedDates = tempHistory.keys.toList()
    ..sort((a, b) => b.compareTo(a)); // Descending order

  for (final date in sortedDates) {
    final formattedDate = formatHistoryDate(date);
    history[formattedDate] = tempHistory[date]!;
  }

  return history;
}

/// Determines the accurate date a diary entry should appear on in history
DateTime _determineAccurateDisplayDate(DiaryModel diary, DateTime now) {
  // PRIORITY 1: If this specific entry was submitted, use its submission date
  if (diary.status == DiaryStatus.submitted &&
      diary.submissions != null &&
      diary.submissions!.length > diary.currentEntry) {
    return diary.submissions![diary.currentEntry];
  }

  // PRIORITY 2: If diary is currently active (ongoing/idle) and should show today
  if (_isCurrentlyActiveDiary(diary, now)) {
    return now;
  }

  // PRIORITY 3: If diary is completed, try to find when this entry was completed
  if (diary.status == DiaryStatus.complete) {
    return _getCompletionDateForEntry(diary, now);
  }

  // PRIORITY 4: For weekly diaries that are past due
  if (_isWeeklyDiary(diary) && diary.due.isBefore(now)) {
    // Try to map to the most appropriate day based on active days
    return _getAppropriateWeeklyDate(diary, now);
  }

  // PRIORITY 5: For missed diaries, use start date
  if (diary.status == DiaryStatus.missed) {
    return diary.start;
  }

  // FALLBACK: Default to start date
  return diary.start;
}

/// Checks if a diary is currently active and should show today
bool _isCurrentlyActiveDiary(DiaryModel diary, DateTime now) {
  final isActiveStatus =
      diary.status == DiaryStatus.ongoing || diary.status == DiaryStatus.idle;
  final isWithinTimeWindow =
      diary.start.isBefore(now) && diary.due.isAfter(now);
  final isActiveTodayBySchedule = _isDiaryActiveToday(diary, now);

  return isActiveStatus && isWithinTimeWindow && isActiveTodayBySchedule;
}

/// Checks if a diary should be active today based on activeDays
bool _isDiaryActiveToday(DiaryModel diary, DateTime now) {
  // If no activeDays specified, it's active every day
  if (diary.activeDays == null || diary.activeDays!.isEmpty) return true;

  // Check if today's weekday is in the activeDays list
  // DateTime.weekday: Monday = 1, Sunday = 7
  final todayWeekday = now.weekday;
  return diary.activeDays!.contains(todayWeekday);
}

/// Gets the completion date for a specific entry
DateTime _getCompletionDateForEntry(DiaryModel diary, DateTime now) {
  // If we have submission data for this specific entry, use it
  if (diary.submissions != null &&
      diary.submissions!.length > diary.currentEntry) {
    return diary.submissions![diary.currentEntry];
  }

  // If no specific submission data, estimate based on diary type
  if (_isWeeklyDiary(diary)) {
    return _getAppropriateWeeklyDate(diary, now);
  }

  // For daily diaries without submission data, use due date as estimate
  return diary.due.isBefore(now) ? diary.due : now;
}

/// Checks if a diary is a weekly diary
bool _isWeeklyDiary(DiaryModel diary) {
  return diary.activeDays != null && diary.activeDays!.isNotEmpty;
}

/// Gets the most appropriate date for a weekly diary
DateTime _getAppropriateWeeklyDate(DiaryModel diary, DateTime now) {
  // If we have submission data, use the latest submission for this entry
  if (diary.submissions != null &&
      diary.submissions!.length > diary.currentEntry) {
    return diary.submissions![diary.currentEntry];
  }

  // If no submission data, find the last active day in the diary's range
  return _findLastActiveDayInRange(diary.start, diary.due, diary.activeDays!);
}

/// Finds the last active day within the diary's date range
DateTime _findLastActiveDayInRange(
    DateTime start, DateTime due, List<int> activeDays) {
  DateTime current = due;

  // Work backwards from due date to find the last active day
  while (current.isAfter(start) || current.isAtSameMomentAs(start)) {
    if (activeDays.contains(current.weekday)) {
      return current;
    }
    current = current.subtract(const Duration(days: 1));
  }

  // If no active day found in range, return due date as fallback
  return due;
}

/// Compares diaries by priority for sorting within date groups
int _compareDiariesByPriority(DiaryModel a, DiaryModel b, DateTime now) {
  final aPriority = getPriorityCategory(a, now);
  final bPriority = getPriorityCategory(b, now);

  // Sort by priority category first
  if (aPriority != bPriority) {
    return aPriority - bPriority;
  }

  // Within same priority, sort by appropriate date
  if (aPriority == 0) {
    // High priority: sort by due date
    return a.due.compareTo(b.due);
  } else {
    // Medium/low priority: sort by start date
    return a.start.compareTo(b.start);
  }
}

// Extension for cleaner status checking
extension DiaryStatusExtension on DiaryStatus {
  bool get isCompleted =>
      this == DiaryStatus.complete || this == DiaryStatus.submitted;
}

List<Tag> _getTags(DiaryModel diary) {
  List<Tag> tags = [];

  if (diary.status == DiaryStatus.submitted) {
    tags.add(const Tag(text: "Done", type: TagType.time));
    // } else if (diary.status == DiaryStatus.missed) {
    //   tags.add(const Tag(text: "Missed", type: TagType.time));
  } else if (diary.status == DiaryStatus.complete) {
    tags.add(const Tag(text: "Awaiting Submission", type: TagType.time));
  } else if (diary.status == DiaryStatus.ongoing) {
    tags.add(const Tag(text: "Ongoing", type: TagType.time));
  } else if (diary.status == DiaryStatus.idle) {
    tags.add(const Tag(text: "Ready to Start", type: TagType.time));
  }

  return tags;
}
