// import 'package:audio_diaries_flutter/core/utils/statuses.dart'
//     show DiaryStatus;
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';

/// Service class to handle daily goal calculations with shifted day boundaries
class DailyGoalService {
  /// Calculates daily goals for all studies for the current shifted day
  Map<StudyModel, DailyGoalData> calculateDailyGoals(
      List<StudyModel> studies, List<DiaryModel> allDiaries,
      {DateTime? targetDay}) {
    final day = targetDay ?? DateTime.now();
    final shiftedBoundaries = _getShiftedDayBoundaries(day);
    final logicalDay = _getLogicalDay(day);

    final Map<StudyModel, DailyGoalData> goalData = {};

    for (var study in studies) {
      // Skip studies with no daily goals
      if (study.goals.daily == 0) {
        continue;
      }

      // Get diaries for this study that are relevant for today
      final studyDiaries = _getStudyDiariesForDay(
          allDiaries, study.studyId, shiftedBoundaries, logicalDay);

      if (studyDiaries.isNotEmpty) {
        // Calculate completed count for this study
        final completedCount =
            _calculateCompletedDiaries(studyDiaries, shiftedBoundaries);

        goalData[study] = DailyGoalData(
          diaries: studyDiaries,
          completed: completedCount,
          target: study.goals.daily,
          progress: _calculateProgress(completedCount, study.goals.daily),
        );
      }
    }

    return goalData;
  }

  /// Gets diaries for a specific study that are relevant for the current day
  List<DiaryModel> _getStudyDiariesForDay(
    List<DiaryModel> allDiaries,
    int studyId,
    ShiftedDayBoundaries boundaries,
    DateTime logicalDay,
  ) {

    return allDiaries.where((diary) {
      // Must belong to this study
      if (diary.studyID != studyId) return false;

      // Must overlap with the shifted day window
      final overlapsWindow = diary.start.isBefore(boundaries.end) &&
          diary.due.isAfter(boundaries.start);
      if (!overlapsWindow) return false;

      // Check active days for weekly diaries
      if (diary.activeDays != null && diary.activeDays!.isNotEmpty) {
        return diary.activeDays!.contains(logicalDay.weekday);
      }

      return true;
    }).toList();
  }

  /// Calculates how many diaries have been completed within the shifted day
  int _calculateCompletedDiaries(
      List<DiaryModel> diaries, ShiftedDayBoundaries boundaries) {
    int completedCount = 0;

    for (var diary in diaries) {
      // Check if this diary has submissions within the shifted day window
      if (diary.submissions != null && diary.submissions!.isNotEmpty) {
        // Count submissions that fall within the shifted day boundaries
        final submissionsInWindow = diary.submissions!.where((submission) {
          return submission.isAfter(boundaries.start) &&
              submission.isBefore(boundaries.end);
        }).length;

        completedCount += submissionsInWindow;
      }
    }

    return completedCount;
  }

  /// Calculates progress percentage (0.0 to 1.0)
  double _calculateProgress(int completed, int target) {
    if (target == 0) return 0.0;
    final progress = completed / target;
    return progress.isNaN || progress.isInfinite
        ? 0.0
        : progress.clamp(0.0, 1.0);
  }

  /// Data class for shifted day boundaries
  ShiftedDayBoundaries _getShiftedDayBoundaries(DateTime day) {
    DateTime baseDate;

    if (day.hour >= 4) {
      baseDate = DateTime(day.year, day.month, day.day);
    } else {
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
  DateTime _getLogicalDay(DateTime currentTime) {
    if (currentTime.hour < 4) {
      return DateTime(currentTime.year, currentTime.month, currentTime.day)
          .subtract(const Duration(days: 1));
    }

    return DateTime(currentTime.year, currentTime.month, currentTime.day);
  }
}

/// Data class to hold daily goal information
class DailyGoalData {
  final List<DiaryModel> diaries;
  final int completed;
  final int target;
  final double progress;

  DailyGoalData({
    required this.diaries,
    required this.completed,
    required this.target,
    required this.progress,
  });

  bool get isComplete => completed >= target;
  int get remaining => (target - completed).clamp(0, target);
}

/// Data class for shifted day boundaries
class ShiftedDayBoundaries {
  final DateTime start;
  final DateTime end;

  ShiftedDayBoundaries({required this.start, required this.end});
}
