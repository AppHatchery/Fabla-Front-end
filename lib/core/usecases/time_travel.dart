import 'dart:convert';

import '../../main.dart';
import '../../objectbox.g.dart';
import '../../screens/diary/domain/entities/diary_entity.dart';
import '../../services/developer_mode_service.dart';
import '../../services/preference_service.dart';
import '../database/dao/diary_dao.dart';
import '../utils/statuses.dart';
import 'notification_manager.dart';

/// A diary's saved status and progress before time travel started.
class DiaryStatusSnapshot {
  final DiaryStatus status;
  final int currentEntry;

  const DiaryStatusSnapshot(this.status, this.currentEntry);
}

/// A status change [planStatusRepairs] would make, and why.
class StatusRepair {
  final Diary diary;
  final DiaryStatus from;
  final DiaryStatus to;
  final String reason;

  const StatusRepair(this.diary, this.from, this.to, this.reason);
}

/// The status changes that undo what time travel did to [diaries], judged
/// against the real [now].
///
/// The status sweep in `DiaryRepository` saves `missed` and `submitted` for
/// diaries past their due date. While travelling forward it does that to
/// diaries that are not really due yet. Two checks, in order:
/// 1. A diary in [snapshot] the sweep marked `missed` or `submitted`, with
///    the same `currentEntry` (nothing was submitted while travelling), gets
///    its snapshotted status back.
/// 2. Otherwise, a status only the sweep could have set on a diary the sweep
///    would not touch yet (due on or after today's 4am cutoff) goes back to
///    idle: `missed` with no entries, or `submitted` with entries left.
List<StatusRepair> planStatusRepairs(
  List<Diary> diaries,
  Map<int, DiaryStatusSnapshot> snapshot,
  DateTime now,
) {
  // Matches the sweep's cutoff in DiaryRepository._getAllDiariesEntities.
  final cutoff = DateTime(now.year, now.month, now.day, 4);
  final repairs = <StatusRepair>[];

  for (final diary in diaries) {
    final current = diary.status ?? DiaryStatus.idle;
    if (current != DiaryStatus.missed && current != DiaryStatus.submitted) {
      continue;
    }
    final before = snapshot[diary.id];

    if (before != null && before.currentEntry == diary.currentEntry) {
      if (before.status != current) {
        repairs.add(StatusRepair(
            diary, current, before.status, 'Restored from before travelling'));
      }
      continue;
    }

    if (diary.due.isBefore(cutoff)) continue;
    if (current == DiaryStatus.missed && diary.currentEntry == 0) {
      repairs.add(StatusRepair(diary, current, DiaryStatus.idle,
          'Marked missed before its due date'));
    } else if (current == DiaryStatus.submitted &&
        diary.currentEntry < diary.entries) {
      repairs.add(StatusRepair(diary, current, DiaryStatus.idle,
          'Marked submitted with entries left, before its due date'));
    }
  }
  return repairs;
}

/// Developer mode time travel: shifts the app's clock and undoes the diary
/// status changes that travelling forward saves.
///
/// Starting a trip snapshots every diary's status and `currentEntry`. Once
/// back in the present, [pendingRepairs] lists what to fix and [repair]
/// applies it, then reschedules notifications.
///
/// Usage example:
/// ```dart
/// await TimeTravel().travel(const Duration(days: 3));
/// await TimeTravel().returnToPresent();
/// final fixed = await TimeTravel().repair();
/// ```
class TimeTravel {
  TimeTravel({
    DiaryDAO? diaryDAO,
    PreferenceService? preferences,
    DeveloperModeService? developerMode,
    void Function()? rescheduleNotifications,
  })  : _diaryDAO = diaryDAO,
        _preferences = preferences ?? PreferenceService(),
        _developerMode = developerMode ?? DeveloperModeService(),
        _rescheduleNotifications = rescheduleNotifications ??
            (() => NotificationManager().scheduleAdditional());

  static const String snapshotKey = 'developer_time_travel_snapshot';

  final DiaryDAO? _diaryDAO;
  final PreferenceService _preferences;
  final DeveloperModeService _developerMode;
  final void Function() _rescheduleNotifications;

  DiaryDAO get _diaries =>
      _diaryDAO ?? DiaryDAO(box: Box<Diary>(objectbox.store));

  /// Shifts the app's clock by [offset] from the device clock. The first trip
  /// takes the snapshot; later trips keep it, so it always describes the
  /// diaries before any travelling.
  Future<void> travel(Duration offset) async {
    if (!_developerMode.isEnabled) return;
    if (offset != Duration.zero && !await hasSnapshot()) {
      await _saveSnapshot();
    }
    await _developerMode.setTimeTravel(offset);
  }

  Future<void> returnToPresent() => _developerMode.setTimeTravel(Duration.zero);

  Future<bool> hasSnapshot() async =>
      await _preferences.getStringPreference(key: snapshotKey) != null;

  /// What [repair] would change. Empty while still travelling, since the
  /// repair has to be judged against the real date.
  Future<List<StatusRepair>> pendingRepairs() async {
    if (_developerMode.isTimeTravelling) return const [];
    return planStatusRepairs(
        _diaries.getAllDiaries(), await _loadSnapshot(), DateTime.now());
  }

  /// Applies [pendingRepairs], clears the snapshot and reschedules
  /// notifications. Returns how many diaries changed.
  Future<int> repair() async {
    if (_developerMode.isTimeTravelling) return 0;
    final repairs = await pendingRepairs();
    for (final repair in repairs) {
      repair.diary.status = repair.to;
    }
    if (repairs.isNotEmpty) {
      _diaries.updateDiaries([for (final r in repairs) r.diary]);
    }
    await _preferences.removePreference(key: snapshotKey);
    _rescheduleNotifications();
    return repairs.length;
  }

  Future<void> _saveSnapshot() async {
    final snapshot = {
      for (final diary in _diaries.getAllDiaries())
        '${diary.id}': [
          (diary.status ?? DiaryStatus.idle).index,
          diary.currentEntry,
        ],
    };
    await _preferences.setStringPreference(
        key: snapshotKey, value: jsonEncode(snapshot));
  }

  Future<Map<int, DiaryStatusSnapshot>> _loadSnapshot() async {
    final stored = await _preferences.getStringPreference(key: snapshotKey);
    if (stored == null) return const {};
    try {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      return {
        for (final entry in decoded.entries)
          int.parse(entry.key): DiaryStatusSnapshot(
            DiaryStatus.values[(entry.value as List)[0] as int],
            (entry.value as List)[1] as int,
          ),
      };
    } catch (_) {
      // Unreadable: fall back to the date-based check alone.
      return const {};
    }
  }
}
