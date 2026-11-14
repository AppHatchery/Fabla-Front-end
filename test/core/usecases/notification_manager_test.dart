// Tests for NotificationManager's pure planning logic.
//
// Times are asserted in local wall-clock terms, so these hold in any timezone;
// run with TZ=America/New_York to also exercise the evening/DST cases that
// used to break (an evening reminder is the next UTC day there, and DST ended
// on 2026-11-01).
import 'package:audio_diaries_flutter/core/usecases/notification_manager.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/notification.dart';
import 'package:flutter_test/flutter_test.dart';

DiaryModel diary({
  required int id,
  required DateTime start,
  required DateTime end,
  required List<Notification> notifications,
  List<int>? activeDays,
  DiaryStatus status = DiaryStatus.idle,
}) =>
    DiaryModel(
      id: id,
      studyID: 1,
      name: 'Diary $id',
      prompts: const [],
      tags: null,
      status: status,
      due: end,
      start: start,
      entries: 1,
      currentEntry: 0,
      end: end,
      notifications: notifications,
      activeDays: activeDays,
      submissions: null,
      completions: null,
    );

Notification note(DateTime localTime) =>
    Notification(title: 't', body: 'b', date: localTime.toUtc());

void main() {
  group('planDiaryNotifications - weekly diaries', () {
    test('evening reminder stays on the active day at the same local time', () {
      final now = DateTime(2026, 11, 1, 8);
      // Wednesdays only, 9:00 PM local (02:00 UTC the next day in US zones).
      final d = diary(
        id: 7,
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 11, 30, 23, 59),
        activeDays: [DateTime.wednesday],
        notifications: [note(DateTime(2026, 10, 1, 21))],
      );

      final planned = NotificationManager.planDiaryNotifications([d], now);

      expect(planned, isNotEmpty);
      for (final p in planned) {
        expect(p.date.weekday, DateTime.wednesday);
        expect(p.date.hour, 21);
        expect(p.date.minute, 0);
      }
      expect(planned.first.date, DateTime(2026, 11, 4, 21));
    });

    test('local time survives a DST change', () {
      // Reminder authored before DST ended (Oct), fires after (Nov).
      final now = DateTime(2026, 10, 20);
      final d = diary(
        id: 3,
        start: DateTime(2026, 10, 20),
        end: DateTime(2026, 11, 10, 23, 59),
        activeDays: [1, 2, 3, 4, 5, 6, 7],
        notifications: [note(DateTime(2026, 10, 20, 9, 30))],
      );

      final planned = NotificationManager.planDiaryNotifications([d], now);

      expect(planned.every((p) => p.date.hour == 9 && p.date.minute == 30),
          isTrue);
      // One per calendar day, none skipped or repeated across the change.
      final days = planned
          .map((p) => DateTime(p.date.year, p.date.month, p.date.day))
          .toSet();
      expect(days.length, planned.length);
      expect(days, contains(DateTime(2026, 11, 1)));
      expect(days, contains(DateTime(2026, 11, 2)));
    });

    test('weeklyDiaryDates includes both ends and only active weekdays', () {
      final d = diary(
        id: 1,
        start: DateTime(2026, 11, 2, 10), // Monday
        end: DateTime(2026, 11, 9, 1), // next Monday
        activeDays: [DateTime.monday],
        notifications: const [],
      );
      expect(NotificationManager.weeklyDiaryDates(d),
          [DateTime(2026, 11, 2), DateTime(2026, 11, 9)]);
    });
  });

  group('planDiaryNotifications - filtering and ordering', () {
    final now = DateTime(2026, 11, 14, 12);

    test('skips past notifications and finished or expired diaries', () {
      final open = diary(
        id: 1,
        start: now,
        end: now.add(const Duration(days: 2)),
        notifications: [
          note(now.subtract(const Duration(hours: 1))),
          note(now.add(const Duration(hours: 1))),
        ],
      );
      final submitted = diary(
        id: 2,
        start: now,
        end: now.add(const Duration(days: 2)),
        status: DiaryStatus.submitted,
        notifications: [note(now.add(const Duration(hours: 2)))],
      );
      final complete = diary(
        id: 3,
        start: now,
        end: now.add(const Duration(days: 2)),
        status: DiaryStatus.complete,
        notifications: [note(now.add(const Duration(hours: 2)))],
      );
      final expired = diary(
        id: 4,
        start: now.subtract(const Duration(days: 2)),
        end: now.subtract(const Duration(hours: 1)),
        notifications: [note(now.add(const Duration(hours: 2)))],
      );

      final planned = NotificationManager.planDiaryNotifications(
          [open, submitted, complete, expired], now);

      expect(planned.map((p) => p.diaryId), [1]);
      expect(planned.single.date, now.add(const Duration(hours: 1)));
    });

    test('keeps the soonest notifications across diaries, up to the limit', () {
      final late = diary(
        id: 1,
        start: now,
        end: now.add(const Duration(days: 30)),
        notifications: [
          for (var i = 10; i < 20; i++) note(now.add(Duration(days: i))),
        ],
      );
      final soon = diary(
        id: 2,
        start: now,
        end: now.add(const Duration(days: 30)),
        notifications: [
          for (var i = 1; i < 5; i++) note(now.add(Duration(days: i))),
        ],
      );

      final planned = NotificationManager.planDiaryNotifications(
          [late, soon], now,
          limit: 5);

      expect(planned.length, 5);
      expect(planned.take(4).every((p) => p.diaryId == 2), isTrue);
      expect(planned.last.diaryId, 1);
      for (var i = 1; i < planned.length; i++) {
        expect(planned[i].date.isAfter(planned[i - 1].date), isTrue);
      }
    });

    test('last reminder asks to open the app only when more are pending', () {
      final d = diary(
        id: 1,
        start: now,
        end: now.add(const Duration(days: 30)),
        notifications: [
          for (var i = 1; i <= 6; i++) note(now.add(Duration(days: i))),
        ],
      );

      final cut =
          NotificationManager.planDiaryNotifications([d], now, limit: 5);
      expect(cut.last.isLast, isTrue);
      expect(cut.last.body, endsWith(lastReminderNote));
      expect(cut.last.payload['last'], '1');
      expect(cut.take(4).any((p) => p.isLast), isFalse);

      final all =
          NotificationManager.planDiaryNotifications([d], now, limit: 6);
      expect(all.any((p) => p.isLast), isFalse);
    });

    test('two diaries at the same time both get scheduled', () {
      final at = now.add(const Duration(hours: 3));
      final planned = NotificationManager.planDiaryNotifications([
        diary(
            id: 1,
            start: now,
            end: at.add(const Duration(hours: 1)),
            notifications: [note(at)]),
        diary(
            id: 2,
            start: now,
            end: at.add(const Duration(hours: 1)),
            notifications: [note(at)]),
      ], now);
      expect(planned.map((p) => p.diaryId).toSet(), {1, 2});
      expect(planned[0].id, isNot(planned[1].id));
    });
  });

  group('notificationId', () {
    test('is deterministic, positive and fits in 31 bits', () {
      final at = DateTime.utc(2026, 11, 14, 21);
      final id = NotificationManager.notificationId(42, at);
      expect(NotificationManager.notificationId(42, at.toLocal()), id);
      expect(id, greaterThanOrEqualTo(0));
      expect(id, lessThanOrEqualTo(0x7FFFFFFF));
    });

    test('differs by diary and by time', () {
      final at = DateTime.utc(2026, 11, 14, 21);
      final id = NotificationManager.notificationId(42, at);
      expect(NotificationManager.notificationId(43, at), isNot(id));
      expect(
          NotificationManager.notificationId(
              42, at.add(const Duration(minutes: 1))),
          isNot(id));
    });
  });
}
