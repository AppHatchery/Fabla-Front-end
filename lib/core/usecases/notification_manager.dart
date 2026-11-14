import 'dart:async';
import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/notification.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/notification_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart' show TimeOfDay;

/// Maximum number of diary notifications kept scheduled at a time.
///
/// iOS only keeps 64 pending local notifications per app; 50 diary
/// notifications plus [userReminderLimit] user reminders stay under that.
const int threshold = 50;

/// Maximum number of "Daily Reminder" notifications kept scheduled.
const int userReminderLimit = 7;

/// A diary notification we want to be scheduled.
class PlannedNotification {
  final int id;
  final int diaryId;
  final String diaryName;
  final String title;
  final String body;

  /// Local fire time.
  final DateTime date;

  const PlannedNotification({
    required this.id,
    required this.diaryId,
    required this.diaryName,
    required this.title,
    required this.body,
    required this.date,
  });

  Map<String, String> get payload => {
        'id': id.toString(),
        'date': date.toUtc().toIso8601String(),
        'diary': diaryId.toString(),
      };
}

/// Owns the set of scheduled local notifications.
///
/// Every public entry point funnels into [sync], which runs one job at a time
/// (callers may fire-and-forget; jobs never overlap) and reconciles what is
/// scheduled against what should be: stale notifications are cancelled,
/// missing ones created. IDs are derived from diary + fire time, so running
/// it repeatedly is idempotent.
class NotificationManager {
  final DiaryRepository diaryRepository = DiaryRepository();
  static final AwesomeNotifications _awesomeNotifications =
      AwesomeNotifications();

  /// Tail of the job queue; shared by all instances.
  static Future<void> _queue = Future.value();

  /// Runs [job] after every previously queued job has finished.
  static Future<void> _serialized(String name, Future<void> Function() job) {
    final run = _queue.then((_) async {
      try {
        await job();
      } catch (e, stack) {
        dev.log('$name failed: $e', name: 'NotificationManager');
        await CrashlyticsService()
            .recordError(e, stack, reason: 'NotificationManager.$name failed');
      }
    });
    _queue = run;
    return run;
  }

  /// Top up / repair the schedule. Safe to call often (app start, resume).
  Future<void> scheduleAdditional() => sync(page: 'home');

  /// Rebuild the schedule after diaries change (e.g. new study data).
  Future<void> scheduleLimit() => sync(page: 'onboarding');

  /// Reconciles diary notifications and user reminders with the database.
  Future<void> sync({String page = 'home'}) => _serialized('sync', () async {
        if (!await _awesomeNotifications.isNotificationAllowed()) {
          dev.log('Notifications not allowed; skipping sync.');
          return;
        }
        await _syncDiaryNotifications(page);
        await _syncUserReminders();
      });

  Future<void> _syncDiaryNotifications(String page) async {
    final planned =
        planDiaryNotifications(diaryRepository.getAllDiaries(), DateTime.now());
    final plannedIds = planned.map((p) => p.id).toSet();

    final scheduled = (await NotificationService.getScheduledNotifications())
        .where((n) => n.content?.payload?['diary'] != null)
        .toList();
    final scheduledIds = <int>{};

    // Cancel anything no longer wanted (completed diaries, old buggy times,
    // random IDs from earlier versions, ...).
    for (final n in scheduled) {
      final id = n.content?.id;
      if (id == null) continue;
      if (plannedIds.contains(id)) {
        scheduledIds.add(id);
      } else {
        await NotificationService.cancelNotification(id);
      }
    }

    int created = 0;
    int failed = 0;
    for (final p in planned) {
      if (scheduledIds.contains(p.id)) continue;
      final ok = await NotificationService.createNotification(
        id: p.id,
        title: p.title,
        body: p.body,
        date: p.date.toUtc(),
        payload: p.payload,
      );
      if (!ok) {
        failed++;
        continue;
      }
      created++;
      await PendoService.track('ScheduleReminder', {
        'status': 'scheduled',
        'page': page,
        'notification_type': 'diary',
        'notification_id': p.id,
        'content': 'Diary: ${p.diaryName}, Title: ${p.title}, Body: ${p.body}',
        'scheduled_time': p.date.toUtc().toIso8601String(),
      });
    }

    dev.log(
        'Diary notifications: planned ${planned.length}, kept ${scheduledIds.length}, '
        'cancelled ${scheduled.length - scheduledIds.length}, created $created, failed $failed',
        name: 'NotificationManager');
    await PendoService.track('ScheduledNotifications', {
      'status': 'scheduled',
      'page': page,
      'scheduled_count': scheduledIds.length + created,
      'failed_count': failed,
    });
    if (failed > 0) {
      await CrashlyticsService().log(
          'NotificationManager: $failed of ${planned.length} diary notifications failed to schedule');
    }
  }

  /// The soonest [limit] notifications that should be scheduled for
  /// [diaries], in fire order.
  @visibleForTesting
  static List<PlannedNotification> planDiaryNotifications(
      List<DiaryModel> diaries, DateTime now,
      {int limit = threshold}) {
    final planned = <PlannedNotification>[];

    for (final diary in diaries) {
      if (!diary.due.isAfter(now)) continue;
      if (diary.status == DiaryStatus.complete ||
          diary.status == DiaryStatus.submitted) {
        continue;
      }

      void add(Notification n, DateTime date) {
        if (!date.isAfter(now)) return;
        planned.add(PlannedNotification(
          id: notificationId(diary.id, date),
          diaryId: diary.id,
          diaryName: diary.name,
          title: n.title,
          body: n.body,
          date: date,
        ));
      }

      if (_isWeeklyDiary(diary)) {
        for (final day in weeklyDiaryDates(diary)) {
          for (final n in diary.notifications) {
            // Keep the reminder's local wall-clock time on each active day so
            // it stays on the right day and survives DST changes.
            final time = TimeOfDay.fromDateTime(n.date.toLocal());
            add(n,
                DateTime(day.year, day.month, day.day, time.hour, time.minute));
          }
        }
      } else {
        for (final n in diary.notifications) {
          add(n, n.date.toLocal());
        }
      }
    }

    planned.sort((a, b) => a.date.compareTo(b.date));
    // Same diary + same minute means the same notification.
    final seen = <int>{};
    planned.retainWhere((p) => seen.add(p.id));
    return planned.take(limit).toList();
  }

  /// Stable, positive 31-bit ID for a diary notification at [date].
  @visibleForTesting
  static int notificationId(int diaryId, DateTime date) =>
      _stableHash('d:$diaryId:${date.toUtc().millisecondsSinceEpoch ~/ 60000}');

  static int _reminderId(DateTime day) =>
      _stableHash('r:${day.year}-${day.month}-${day.day}');

  /// 32-bit FNV-1a, masked to a positive int (platform notification IDs are
  /// 32-bit signed).
  static int _stableHash(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  /// Cancel all scheduled notifications for diary [id].
  Future<void> cancelDiaryNotifications(int id) =>
      _serialized('cancelDiaryNotifications', () async {
        dev.log('Cancelling notifications for diary $id');
        for (final n in await NotificationService.getScheduledNotifications()) {
          final nid = n.content?.id;
          if (nid != null && n.content?.payload?['diary'] == id.toString()) {
            await NotificationService.cancelNotification(nid);
          }
        }
      });

  //TODO: Implement 1. daily goal notifications 2. continue notifications 3. submit diary notifications

  /// Schedule up to [userReminderLimit] user reminders, only on days that
  /// have diaries due.
  Future<void> scheduleUserReminders() =>
      _serialized('scheduleUserReminders', _syncUserReminders);

  Future<void> removeUserReminders() =>
      _serialized('removeUserReminders', _cancelUserReminders);

  Future<List<NotificationModel>> _scheduledUserReminders() async =>
      (await NotificationService.getScheduledNotifications())
          .where((n) => n.content?.payload?['type'] == 'reminder')
          .toList();

  Future<void> _cancelUserReminders() async {
    for (final n in await _scheduledUserReminders()) {
      final id = n.content?.id;
      if (id != null) await NotificationService.cancelNotification(id);
    }
  }

  Future<void> _syncUserReminders() async {
    final timesFromString = await PreferenceService()
        .getStringListPreference(key: 'reminder_times');
    final times = timesFromString
            ?.map((e) => TimeOfDay.fromDateTime(DateTime.parse(e).toLocal()))
            .toList() ??
        [];
    if (times.isEmpty) {
      dev.log('No reminder times set by user, skipping reminders.');
      await _cancelUserReminders();
      return;
    }
    times.sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    final time = times.first;

    final now = DateTime.now();
    final diaryDays = diaryRepository
        .getEveryDiary()
        .where((d) => d.due.isAfter(now))
        .map((d) {
      final due = d.due.toLocal();
      return DateTime(due.year, due.month, due.day);
    }).toSet();

    // Plan the next reminders, looking ahead up to 30 days.
    final planned = <int, DateTime>{};
    for (int offset = 0;
        offset < 30 && planned.length < userReminderLimit;
        offset++) {
      final day = DateTime(now.year, now.month, now.day + offset);
      if (!diaryDays.contains(day)) continue;
      final fireAt =
          DateTime(day.year, day.month, day.day, time.hour, time.minute);
      if (!fireAt.isAfter(now)) continue;
      planned[_reminderId(day)] = fireAt;
    }

    final keep = <int>{};
    for (final n in await _scheduledUserReminders()) {
      final id = n.content?.id;
      if (id == null) continue;
      final scheduledAt = DateTime.tryParse(n.content?.payload?['fire'] ?? '');
      if (planned.containsKey(id) &&
          scheduledAt != null &&
          scheduledAt.isAtSameMomentAs(planned[id]!)) {
        keep.add(id);
      } else {
        await NotificationService.cancelNotification(id);
      }
    }

    for (final entry in planned.entries) {
      if (keep.contains(entry.key)) continue;
      final day = entry.value;
      await NotificationService.createNotification(
        id: entry.key,
        title: 'Daily Reminder',
        body: 'Time to check your Fabla entries!',
        date: entry.value.toUtc(),
        payload: {
          'id': entry.key.toString(),
          'date': DateTime(day.year, day.month, day.day).toIso8601String(),
          'fire': entry.value.toUtc().toIso8601String(),
          'type': 'reminder',
        },
      );
      dev.log(
          'Scheduled user reminder - id: ${entry.key}, date: ${entry.value}');
    }
  }

  static bool _isWeeklyDiary(DiaryModel diary) =>
      diary.activeDays != null && diary.activeDays!.isNotEmpty;

  /// Local calendar dates (midnight) on which a weekly diary is active.
  @visibleForTesting
  static List<DateTime> weeklyDiaryDates(DiaryModel diary) {
    final s = diary.start.toLocal();
    final e = diary.end.toLocal();
    final dates = <DateTime>[];
    // Step by calendar day (not 24h) so DST changes don't skip/repeat days.
    for (var d = DateTime(s.year, s.month, s.day);
        !d.isAfter(DateTime(e.year, e.month, e.day));
        d = DateTime(d.year, d.month, d.day + 1)) {
      if (diary.activeDays!.contains(d.weekday)) dates.add(d);
    }
    return dates;
  }
}
