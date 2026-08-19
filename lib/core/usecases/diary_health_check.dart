import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';

/// How serious a [DiaryHealthIssue] is.
///
/// - [critical]: the diary is unusable as configured (e.g. it can never
///   become available, or has no questions).
/// - [warning]: the diary is usable but in a state that likely isn't what
///   was intended (e.g. marked submitted before all entries were used).
/// - [info]: worth a look, but plausibly intentional.
enum HealthSeverity { critical, warning, info }

/// A single flagged issue for one diary.
class DiaryHealthIssue {
  final String ruleId;
  final HealthSeverity severity;
  final String message;
  final int studyID;
  final String? studyName;
  final int diaryId;
  final String diaryName;

  const DiaryHealthIssue({
    required this.ruleId,
    required this.severity,
    required this.message,
    required this.studyID,
    required this.studyName,
    required this.diaryId,
    required this.diaryName,
  });

  @override
  String toString() =>
      '[${severity.name}] $ruleId — study $studyID${studyName != null ? ' ("$studyName")' : ''}, diary $diaryId ("$diaryName"): $message';
}

/// Inspects a single diary in isolation. [study] is the diary's parent
/// study/experiment config, when the caller has it available, for rules
/// that need goal/incentive context. [now] is the current wall-clock time,
/// injectable so rules that reason about "now" stay testable.
typedef DiaryRule = DiaryHealthIssue? Function(
    DiaryModel diary, StudyModel? study, DateTime now);

/// Inspects every diary belonging to the same study together, so it can
/// reason about the schedule as a whole (gaps, duplicates, overlaps).
typedef DiaryGroupRule = List<DiaryHealthIssue> Function(
    List<DiaryModel> studyDiaries, StudyModel? study);

DiaryHealthIssue _issue(
  DiaryModel diary,
  StudyModel? study,
  String ruleId,
  HealthSeverity severity,
  String message,
) {
  return DiaryHealthIssue(
    ruleId: ruleId,
    severity: severity,
    message: message,
    studyID: diary.studyID,
    studyName: study?.name,
    diaryId: diary.id,
    diaryName: diary.name,
  );
}

String _dateLabel(DateTime date) => date.toIso8601String().split('T').first;
DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

// ---------------------------------------------------------------------------
// Per-diary rules
// ---------------------------------------------------------------------------

DiaryHealthIssue? _zeroDurationWindow(
    DiaryModel diary, StudyModel? study, DateTime now) {
  if (!diary.start.isAtSameMomentAs(diary.end)) return null;
  return _issue(diary, study, 'zero_duration_window', HealthSeverity.critical,
      'start and end are identical (${diary.start}) — the diary can never be open.');
}

DiaryHealthIssue? _reversedWindow(
    DiaryModel diary, StudyModel? study, DateTime now) {
  if (!diary.start.isAfter(diary.due)) return null;
  return _issue(diary, study, 'reversed_window', HealthSeverity.critical,
      'start (${diary.start}) is after due (${diary.due}).');
}

DiaryHealthIssue? _invalidEntryLimit(
    DiaryModel diary, StudyModel? study, DateTime now) {
  if (diary.entries > 0) return null;
  return _issue(diary, study, 'invalid_entry_limit', HealthSeverity.critical,
      'entries limit is ${diary.entries}; must be at least 1.');
}

DiaryHealthIssue? _invalidCurrentEntry(
    DiaryModel diary, StudyModel? study, DateTime now) {
  if (diary.currentEntry >= 0 && diary.currentEntry <= diary.entries) {
    return null;
  }
  return _issue(diary, study, 'invalid_current_entry', HealthSeverity.critical,
      'currentEntry (${diary.currentEntry}) is out of range for entries (${diary.entries}).');
}
//? Verify case
DiaryHealthIssue? _prematureSubmission(
    DiaryModel diary, StudyModel? study, DateTime now) {
  if (diary.status != DiaryStatus.submitted) return null;
  if (diary.currentEntry >= diary.entries) return null;
  return _issue(diary, study, 'premature_submission', HealthSeverity.warning,
      'marked submitted after only ${diary.currentEntry}/${diary.entries} entries — '
      'the remaining entries are now unreachable.');
}
//? Verify case
DiaryHealthIssue? _missedWithProgress(
    DiaryModel diary, StudyModel? study, DateTime now) {
  if (diary.status != DiaryStatus.missed || diary.currentEntry <= 0) {
    return null;
  }
  final entryWord = diary.currentEntry == 1 ? 'entry' : 'entries';
  return _issue(diary, study, 'missed_with_progress', HealthSeverity.warning,
      'marked missed despite ${diary.currentEntry} recorded $entryWord.');
}

/// Catches a diary being permanently mislabeled `missed` by a temporary
/// device clock error: if the participant sets their phone's date forward,
/// any status sweep that runs while it's wrong can write `missed` to a
/// diary whose real due date hasn't passed yet. That write persists, and
/// once the clock is corrected the diary's due date is back in the future
/// — a clear sign the `missed` status was set incorrectly rather than
/// reflecting an actual missed window.
DiaryHealthIssue? _missedBeforeDue(
    DiaryModel diary, StudyModel? study, DateTime now) {
  if (diary.status != DiaryStatus.missed) return null;
  if (!diary.due.isAfter(now)) return null;
  return _issue(diary, study, 'missed_before_due', HealthSeverity.warning,
      'marked missed even though its due date (${diary.due}) is still in the future relative to now ($now) — '
      'likely caused by the device clock being set forward and later corrected.');
}
//? Tune for weekly and daily diaries
DiaryHealthIssue? _invalidActiveDays(
    DiaryModel diary, StudyModel? study, DateTime now) {
  final days = diary.activeDays;
  if (days == null) return null;
  if (days.isEmpty) {
    return _issue(diary, study, 'empty_active_days', HealthSeverity.warning,
        'activeDays is an empty list, so the diary can never be active — use null for a daily diary instead.');
  }
  final outOfRange = days.where((day) => day < 1 || day > 7).toList();
  if (outOfRange.isEmpty) return null;
  return _issue(diary, study, 'invalid_active_day_value', HealthSeverity.critical,
      'activeDays contains invalid weekday value(s) $outOfRange (expected 1-7).');
}

DiaryHealthIssue? _noPrompts(
    DiaryModel diary, StudyModel? study, DateTime now) {
  if (diary.prompts.isNotEmpty) return null;
  return _issue(diary, study, 'no_prompts', HealthSeverity.critical,
      'diary has no questions at all.');
}

DiaryHealthIssue? _timerPromptMissingDuration(
    DiaryModel diary, StudyModel? study, DateTime now) {
  final broken = diary.prompts.where((prompt) =>
      prompt.responseType == ResponseType.timer &&
      (prompt.option?.timerLength == null ||
          prompt.option!.timerLength == Duration.zero));
  if (broken.isEmpty) return null;
  return _issue(diary, study, 'timer_missing_duration', HealthSeverity.critical,
      '${broken.length} timer question(s) have no usable timer length.');
}

//? Verify case
DiaryHealthIssue? _requiredPromptOnZeroGoalStudy(
    DiaryModel diary, StudyModel? study, DateTime now) {
  if (study == null) return null;
  if (study.goals.daily != 0 || study.goals.weekly != 0) return null;
  if (!diary.prompts.any((prompt) => prompt.required)) return null;
  return _issue(diary, study, 'required_prompt_on_optional_study',
      HealthSeverity.info,
      'study "${study.name}" has no daily/weekly goal (i.e. is optional) but this diary requires answers.');
}

DiaryHealthIssue? _notificationsOutsideWindow(
    DiaryModel diary, StudyModel? study, DateTime now) {
  final outside = diary.notifications.where((notification) {
    final local = notification.date.toLocal();
    return local.isBefore(diary.start) || local.isAfter(diary.due);
  });
  if (outside.isEmpty) return null;
  return _issue(diary, study, 'notification_outside_window', HealthSeverity.warning,
      '${outside.length} notification(s) scheduled outside the diary\'s start/due window.');
}

const List<DiaryRule> _perDiaryRules = [
  _zeroDurationWindow,
  _reversedWindow,
  _invalidEntryLimit,
  _invalidCurrentEntry,
  _prematureSubmission,
  _missedWithProgress,
  _missedBeforeDue,
  _invalidActiveDays,
  _noPrompts,
  _timerPromptMissingDuration,
  _requiredPromptOnZeroGoalStudy,
  _notificationsOutsideWindow,
];

// ---------------------------------------------------------------------------
// Group (schedule-level) rules — applied to all diaries of one study
// ---------------------------------------------------------------------------
//? Verify case
List<DiaryHealthIssue> _duplicateScheduleDates(
    List<DiaryModel> diaries, StudyModel? study) {
  final byDate = <DateTime, List<DiaryModel>>{};
  for (final diary in diaries) {
    byDate.putIfAbsent(_dateOnly(diary.start), () => []).add(diary);
  }

  final issues = <DiaryHealthIssue>[];
  for (final entry in byDate.entries) {
    if (entry.value.length <= 1) continue;
    for (final diary in entry.value) {
      issues.add(_issue(diary, study, 'duplicate_schedule_date',
          HealthSeverity.warning,
          '${entry.value.length} diaries in this study start on ${_dateLabel(entry.key)}.'));
    }
  }
  return issues;
}
//? Verify case
List<DiaryHealthIssue> _overlappingWindows(
    List<DiaryModel> diaries, StudyModel? study) {
  final sorted = List<DiaryModel>.from(diaries)
    ..sort((a, b) => a.start.compareTo(b.start));

  final issues = <DiaryHealthIssue>[];
  for (var i = 1; i < sorted.length; i++) {
    final previous = sorted[i - 1];
    final current = sorted[i];
    if (current.start.isBefore(previous.due)) {
      issues.add(_issue(current, study, 'overlapping_window',
          HealthSeverity.warning,
          'starts (${current.start}) before the previous diary in this study is due (${previous.due}).'));
    }
  }
  return issues;
}
//? Verify case
List<DiaryHealthIssue> _scheduleGaps(
    List<DiaryModel> diaries, StudyModel? study) {
  // Only diaries with no active-day restriction are expected to recur every
  // calendar day, so gaps are only meaningful within that subset.
  final dailyCadence = diaries.where((diary) => diary.activeDays == null).toList()
    ..sort((a, b) => a.start.compareTo(b.start));

  final issues = <DiaryHealthIssue>[];
  for (var i = 1; i < dailyCadence.length; i++) {
    final previousDate = _dateOnly(dailyCadence[i - 1].start);
    final currentDate = _dateOnly(dailyCadence[i].start);
    final gapDays = currentDate.difference(previousDate).inDays;
    if (gapDays > 1) {
      issues.add(_issue(
          dailyCadence[i],
          study,
          'schedule_gap',
          HealthSeverity.info,
          'missing ${gapDays - 1} day(s) in the daily schedule between '
              '${_dateLabel(previousDate)} and ${_dateLabel(currentDate)}.'));
    }
  }
  return issues;
}
//? Verify case
List<DiaryHealthIssue> _inconsistentActiveDays(
    List<DiaryModel> diaries, StudyModel? study) {
  if (diaries.length <= 1) return [];
  String key(List<int>? days) =>
      days == null ? 'null' : (List<int>.from(days)..sort()).join(',');
  final distinctConfigs = diaries.map((diary) => key(diary.activeDays)).toSet();
  if (distinctConfigs.length <= 1) return [];
  return [
    _issue(diaries.first, study, 'inconsistent_active_days',
        HealthSeverity.warning,
        'diaries in this study disagree on activeDays configuration ($distinctConfigs) — expected one consistent schedule per study.'),
  ];
}
//? Verify case
List<DiaryHealthIssue> _inconsistentEntryLimit(
    List<DiaryModel> diaries, StudyModel? study) {
  if (diaries.length <= 1) return [];
  final distinctLimits = diaries.map((diary) => diary.entries).toSet();
  if (distinctLimits.length <= 1) return [];
  return [
    _issue(diaries.first, study, 'inconsistent_entry_limit', HealthSeverity.info,
        'diaries in this study disagree on the max entries-per-day value ($distinctLimits).'),
  ];
}

const List<DiaryGroupRule> _groupRules = [
  _duplicateScheduleDates,
  _overlappingWindows,
  _scheduleGaps,
  _inconsistentActiveDays,
  _inconsistentEntryLimit,
];

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// A thorough health check for the diary feature: flags data-integrity
/// issues in scheduled diaries — malformed windows, inconsistent submission
/// state, and schedule-level anomalies (gaps, duplicates, overlaps) — with
/// no knowledge of which study or experiment the diaries belong to.
///
/// Use [checkDiary] to inspect a single diary (e.g. right after it's parsed
/// from the server), or [checkAll] to run every rule, including the
/// schedule-level ones, across a participant's full diary list.
class DiaryHealthCheck {
  const DiaryHealthCheck();

  /// Runs only the per-diary rules against a single diary. [now] defaults
  /// to the current time; pass an explicit value in tests.
  List<DiaryHealthIssue> checkDiary(DiaryModel diary,
      {StudyModel? study, DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();
    return _perDiaryRules
        .map((rule) => rule(diary, study, effectiveNow))
        .whereType<DiaryHealthIssue>()
        .toList();
  }

  /// Runs every rule — per-diary and schedule-level — across [diaries],
  /// which may span multiple studies. [studiesById] is optional; when
  /// provided (keyed by [DiaryModel.studyID]), rules that need study
  /// config (e.g. goals, name) can use it. [now] defaults to the current
  /// time; pass an explicit value in tests.
  List<DiaryHealthIssue> checkAll(
    List<DiaryModel> diaries, {
    Map<int, StudyModel>? studiesById,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final issues = <DiaryHealthIssue>[];
    final byStudy = <int, List<DiaryModel>>{};

    for (final diary in diaries) {
      byStudy.putIfAbsent(diary.studyID, () => []).add(diary);
      final study = studiesById?[diary.studyID];
      for (final rule in _perDiaryRules) {
        final issue = rule(diary, study, effectiveNow);
        if (issue != null) issues.add(issue);
      }
    }

    for (final entry in byStudy.entries) {
      final study = studiesById?[entry.key];
      for (final rule in _groupRules) {
        issues.addAll(rule(entry.value, study));
      }
    }

    return issues;
  }
}
