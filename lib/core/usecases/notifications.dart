import 'dart:convert';
import 'dart:math';
import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../services/pendo_service.dart';
import '../../services/preference_service.dart';

/// Cancels all scheduled diary notifications for a specific diary with the given [id].
///
/// This function is responsible for canceling all previously scheduled diary notifications
/// associated with a particular item identified by its [id]. It retrieves the existing
/// diary notifications from the app's preferences, checks for notifications related to the
/// provided diary [id], and cancels each of them using the [NotificationService].
///
/// Parameters:
/// - [id]: The identifier of the item for which diary notifications should be canceled.
///
/// Usage example:
/// ```dart
/// cancelAllDiaryNotifications(123);
/// ```
void cancelAllDiaryNotifications(int id) async {
  final source =
      await PreferenceService().getStringPreference(key: 'diary_notifications');

  if (source == null) {
    return;
  }

  Map<String, dynamic> jsonMap = json.decode(source);

  final Map<int, List<int>> notifications = jsonMap.map(
    (key, value) => MapEntry(int.parse(key), List<int>.from(value)),
  );

  final notificationsForId = notifications[id];

  if (notificationsForId != null) {
    for (int notification in notificationsForId) {
      await NotificationService.cancelNotification(notification);
    }

    notifications[id] = [];

    Map<String, dynamic> jsonMap = notifications.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final encoded = json.encode(jsonMap);
    await PreferenceService()
        .setStringPreference(key: 'diary_notifications', value: encoded);
  }
}

/// cancels all scheduled continue diary and submit diary notifications for a specific diary with the given [id].
///
/// This function is responsible for canceling all previously scheduled continue diary and submit diary notifications
/// associated with a particular item identified by its [id]. It retrieves the existing
/// continue diary and submit diary notifications from the app's preferences, checks for notifications related to the
/// provided diary [id], and cancels each of them using the [NotificationService].
///
/// Parameters:
/// - [id]: The identifier of the item for which continue diary and submit diary notifications should be canceled.
///
void cancelContinueNotifications(int id) async {
  final source = await PreferenceService()
      .getStringPreference(key: 'continue_notifications');

  if (source == null) {
    return;
  }

  Map<String, dynamic> jsonMap = json.decode(source);
  final Map<int, List<int>> notifications = jsonMap.map(
    (key, value) => MapEntry(int.parse(key), List<int>.from(value)),
  );

  final notificationsForId = notifications[id];

  if (notificationsForId != null) {
    for (int notification in notificationsForId) {
      await NotificationService.cancelNotification(notification);
    }

    notifications[id] = [];

    Map<String, dynamic> jsonMap = notifications.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final encoded = json.encode(jsonMap);
    await PreferenceService()
        .setStringPreference(key: 'continue_notifications', value: encoded);
  }
}

/// Schedules or reschedules a "Continue Diary" notification for a specific diary with the given [id].
///
/// This function is responsible for scheduling or rescheduling a "Continue Diary" notification for a
/// particular item identified by its [id]. It first retrieves the existing continue diary notifications from
/// the app's preferences, if continue notification preference is not empty, checks for notifications related to the provided [id], and cancels any existing
/// notifications for that item. Then, it calculates the appropriate time for the new notification,
/// creates the notification using the [NotificationService], and updates the stored notifications information
/// in the preferences.
/// If the continue notification is empty, it will schedule a new continue notification for the diary.
///
/// Parameters:
/// - [id]: The identifier of the item for which a "Continue Diary" notification should be scheduled.
///
/// Usage example:
/// ```dart
/// scheduleContinueDiaryNotifications(123);
/// ```
void scheduleContinueDiaryNotifications(int id) async {
  dev.log("Diary ID: $id", name: "Continue");
  final source = await PreferenceService()
      .getStringPreference(key: 'continue_notifications');

  Map<int, List<int>> notifications;
  notifications = {};
  if (source == null) {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day, 23, 59);

    List<DateTime> reminderTimes = [];

    if (now.isBefore(midnight)) {
      if (now.add(const Duration(minutes: 30)).isBefore(midnight)) {
        reminderTimes.add(now.add(const Duration(minutes: 30)));
      }
      if (now.add(const Duration(hours: 6)).isBefore(midnight)) {
        reminderTimes.add(now.add(const Duration(hours: 6)));
      }
    } else {
      return;
    }

    final List<int> notificationIDs = [];

    for (final time in reminderTimes) {
      final notificationID = Random().nextInt(100000);
      notificationIDs.add(notificationID);
      await NotificationService.createNotification(
          id: notificationID,
          title: 'Continue where you left off!',
          body:
              "Looks like you started a diary entry but haven’t finished. Tap here to continue.",
          date: time,  payload: {"type": "continue"});

      dev.log("Time Scheduled: ${time.hour}:${time.minute}",
          name: "Continue Reminders");

      await PendoService.track("ScheduleReminder", {
        "status": "scheduled",
        "page": "diary",
        "notification_type": "continue",
        "scheduled_time": "${time.hour}:${time.minute}",
      });
    }

    notifications[id] = notificationIDs;

    final updatedJsonMap = Map<String, dynamic>.fromEntries(notifications
        .entries
        .map((entry) => MapEntry(entry.key.toString(), entry.value)));

    final encoded = json.encode(updatedJsonMap);
    await PreferenceService()
        .setStringPreference(key: 'continue_notifications', value: encoded);
  } else {
    final Map<String, dynamic> jsonMap = json.decode(source);
    if (jsonMap.containsKey(id.toString())) {
      final notifications = Map<int, List<int>>.fromEntries(jsonMap.entries.map(
          (entry) =>
              MapEntry(int.parse(entry.key), List<int>.from(entry.value))));

      final notificationsForId = notifications[id];

      if (notificationsForId != null) {
        for (int notification in notificationsForId) {
          await NotificationService.cancelNotification(notification);
        }
        notificationsForId.clear();

        final now = DateTime.now();
        final midnight = DateTime(now.year, now.month, now.day, 23, 59);

        List<DateTime> reminderTimes = [];

        if (now.isBefore(midnight)) {
          if (now.add(const Duration(minutes: 30)).isBefore(midnight)) {
            reminderTimes.add(now.add(const Duration(minutes: 30)));
          }
          if (now.add(const Duration(hours: 6)).isBefore(midnight)) {
            reminderTimes.add(now.add(const Duration(hours: 6)));
          }
        } else {
          return;
        }

        final List<int> notificationIDs = [];

        for (final time in reminderTimes) {
          final notificationID = Random().nextInt(100000);
          notificationIDs.add(notificationID);
          await NotificationService.createNotification(
              id: notificationID,
              title: 'Continue where you left off!',
              body:
                  "Looks like you started a diary entry but haven’t finished. Tap here to continue.",
              date: time,  payload: {"type": "continue"});

          dev.log("Time Scheduled: ${time.hour}:${time.minute}",
              name: "Continue Reminders");

          await PendoService.track("ScheduleReminder", {
            "status": "scheduled",
            "page": "diary",
            "notification_type": "continue",
            "scheduled_time": "${time.hour}:${time.minute}",
          });
        }

        notifications[id] = notificationIDs;

        final updatedJsonMap = Map<String, dynamic>.fromEntries(notifications
            .entries
            .map((entry) => MapEntry(entry.key.toString(), entry.value)));

        final encoded = json.encode(updatedJsonMap);
        await PreferenceService()
            .setStringPreference(key: 'continue_notifications', value: encoded);
      }
    }
  }
}

/// Schedules or reschedules a "Submit Diary" notification for a specific diary with the given [id].
///
/// This function is responsible for scheduling or rescheduling a "Submit Diary" notification for a
/// particular item identified by its [id]. It first retrieves the existing continue notifications from
/// the app's preferences, if continue notification preference is not empty, checks for notifications related to the provided [id], and cancels any existing
/// notifications for that item. Then, it calculates the appropriate time for the new notification,
/// creates the notification using the [NotificationService], and updates the stored notifications information
/// in the preferences.
/// If the continue notification is empty, it will schedule a new submit notification for the diary.
///
/// Parameters:
/// - [id]: The identifier of the item for which a "Submit Diary" notification should be scheduled.
///
/// Usage example:
/// ```dart
/// scheduleSubmitDiaryNotification(123);
/// ```
void scheduleSubmitDiaryNotification(int id) async {
  final source = await PreferenceService()
      .getStringPreference(key: 'continue_notifications');

  if (source == null) {
    return;
  }

  final Map<String, dynamic> jsonMap = json.decode(source);

  if (jsonMap.containsKey(id.toString())) {
    final notifications = Map<int, List<int>>.fromEntries(jsonMap.entries.map(
        (entry) =>
            MapEntry(int.parse(entry.key), List<int>.from(entry.value))));

    final notificationsForId = notifications[id];

    if (notificationsForId != null) {
      final now = DateTime.now();
      final sevenPM = DateTime(now.year, now.month, now.day, 19);

      DateTime reminderTime;

      if (now.isBefore(sevenPM)) {
        reminderTime = now.add(const Duration(minutes: 10));
      } else {
        return;
      }

      final notificationID = Random().nextInt(100000);
      await NotificationService.createNotification(
          id: notificationID,
          title: 'Your Entry Is Ready for Submission!',
          body:
              "You've completed your entry. Fantastic! Just one more step: hit 'Submit' to share your valuable thoughts.",
          date: reminderTime,  payload: {"type": "submit"});

      notifications[id] = [notificationID];
      dev.log("Time Scheduled: ${reminderTime.hour}:${reminderTime.minute}",
          name: "Submit Reminders");

      await PendoService.track("ScheduleReminder", {
        "status": "scheduled",
        "page": "summary",
        "notification_type": "submit",
        "scheduled_time": "${reminderTime.hour}:${reminderTime.minute}",
      });

      final updatedJsonMap = Map<String, dynamic>.fromEntries(notifications
          .entries
          .map((entry) => MapEntry(entry.key.toString(), entry.value)));

      final encoded = json.encode(updatedJsonMap);
      await PreferenceService()
          .setStringPreference(key: 'continue_notifications', value: encoded);
    }
  }
}

/// Schedules a notification to remind the user to complete their daily goal.
///
/// This function is responsible for scheduling a notification to remind the user to complete their daily goal.
/// It first retrieves the existing reminder times from the app's preferences. If the reminder times are not empty,
/// it calculates the appropriate time for the new notification, creates the notification using the [NotificationService],
/// and updates the stored notifications information in the preferences.
/// If the reminder times are empty, it will schedule a new daily goal notification for the diary.
///
/// Parameters:
/// - [id]: The identifier of the item for which a daily goal notification should be scheduled.
///
void dailyGoalNotification(int id, int entriesLeft) async {
  final source =
      await PreferenceService().getStringListPreference(key: 'reminder_times');
  final dailySource =
      await PreferenceService().getStringPreference(key: 'daily_notifications');
  Map<int, List<int>> notifications = {};

  // If there are no reminder times, schedule a notification for 3 PM
  final value = source?.lastOrNull;
  final last = DateTime.tryParse(value ?? "");
  final potential = retrieveNotificationDate(last);

  if (potential != null) {
    //cancel the notification
    if (dailySource != null) {
      final Map<String, dynamic> jsonMap = json.decode(dailySource);
      notifications = Map<int, List<int>>.fromEntries(jsonMap.entries.map(
          (entry) =>
              MapEntry(int.parse(entry.key), List<int>.from(entry.value))));
      final notificationsForId = notifications[id];

      if (notificationsForId != null) {
        for (int notification in notificationsForId) {
          // await PendoService.track("ScheduleReminder", {
          //   "status": "cancelled",
          //   "page": "completion",
          //   "notification_type": "reminder",
          //   "scheduled_time": "${n.schedule.hour}:${potential.minute}",
          // });

          await NotificationService.cancelNotification(notification);
        }
      }
    }
    final notificationID = Random().nextInt(100000);
    await NotificationService.createNotification(
        id: notificationID,
        title: 'You are close to your daily goal!',
        body:
            'Hey, you are just $entriesLeft conversation away from your daily goal. Keep it in mind as you wrap up your day and you talk to any staff along the way',
        date: potential,  payload: {"type": "dailygoal"});

    dev.log("Time Scheduled: ${potential.hour}:${potential.minute}",
        name: "Daily Goal Reminders");
    await PendoService.track("ScheduleReminder", {
      "status": "scheduled",
      "page": "completion",
      "notification_type": "dailygoal",
      "scheduled_time": "${potential.hour}:${potential.minute}",
    });

    notifications[id] = [notificationID];
    final updatedJsonMap = Map<String, dynamic>.fromEntries(notifications
        .entries
        .map((entry) => MapEntry(entry.key.toString(), entry.value)));
    final encoded = json.encode(updatedJsonMap);
    await PreferenceService()
        .setStringPreference(key: 'daily_notifications', value: encoded);
  }
}

/// Retrieves the next notification date based on the provided last notification date.
/// This function calculates the next notification time
///
/// Parameters:
/// - [last]: The DateTime object representing the last notification time, or null if there was no previous notification.
///
/// Returns:
/// A DateTime object representing the next notification time, or null if the conditions are not met.
DateTime? retrieveNotificationDate(DateTime? last) {
  // Check if the last notification time is null
  if (last == null) {
    // If last is null, return the current time + 2hrs and should not surpass 6pm
    final now = DateTime.now();
    final time = now.add(const Duration(hours: 2)); // 2 hours from now
    final sixPM = DateTime(now.year, now.month, now.day, 18); // 6 PM today

    return time.isBefore(sixPM) ? time : null;
  } else {
    // Get the current date and time
    final now = DateTime.now();
    // Define 3 PM and 7 PM of the current day
    final threePM = DateTime(now.year, now.month, now.day, 15); // 3 PM today
    final sixPM = DateTime(now.year, now.month, now.day, 18); // 7 PM today

    // Get the actual reminder time based on the last notification time on the current day
    final actualReminderTime =
        DateTime(now.year, now.month, now.day, last.hour, last.minute);

    // Declare a variable to hold the calculated reminder time
    late DateTime? reminderTime;

    // Determine the reminder time based on whether it is before or after 3 PM
    if (actualReminderTime.isBefore(threePM)) {
      // If the actual reminder time is before 3 PM
      reminderTime =
          DateTime(now.year, now.month, now.day, 16, 30); // 4:30 PM today
    } else if ((actualReminderTime.isAtSameMomentAs(threePM) ||
        actualReminderTime.isAfter(threePM))) {
      // If the actual reminder time is at the same moment or after 3 PM
      reminderTime = now.add(const Duration(hours: 1)).isBefore(sixPM)
          ? now.add(const Duration(hours: 1))
          : null;
    }

    // Return the calculated reminder time
    return reminderTime;
  }
}

void lateAfternoonNotifications(List<DiaryModel> diaries) async {
  const title = "Let's submit some entries!";
  const body =
      "Hey, it looks like you haven't made an entry yet. Don't worry; you can still submit an entry to record your interactions with staff! Click here to begin now.";

  final source =
      await PreferenceService().getStringListPreference(key: 'reminder_times');
  final dailySource =
      await PreferenceService().getStringPreference(key: 'diary_notifications');
  Map<int, List<int>> notifications = {};

  if (source == null) {
    for (final diary in diaries) {
      // Schedule late afternoon reminders
      // the reminder gets fired randomly between 1pm and 3pm
      final date = diary.start;
      final notificationDate = DateTime(date.year, date.month, date.day,
          Random().nextInt(3) + 13, Random().nextInt(60));

      final id = Random().nextInt(100000);
      await NotificationService.createNotification(
          id: id, title: title, body: body, date: notificationDate,  payload: {"type": "reminder"});
      await PendoService.track("ScheduleReminder", {
        "status": "scheduled",
        "page": "onboarding",
        "notification_type": "reminder",
        "scheduled_time": "${notificationDate.hour}:${notificationDate.minute}",
      });
    }
  } else {
    final times =
        source.map((e) => TimeOfDay.fromDateTime(DateTime.parse(e))).toList();
    times.sort((a, b) =>
        (a.hour + a.minute / 60.0).compareTo(b.hour + b.minute / 60.0));

    dev.log("Times: $times", name: "Late Afternoon Reminders");

    List<TimeOfDay> lateReminders =
        times.where((element) => element.hour >= 15).toList();

    if (dailySource != null) {
      final Map<String, dynamic> jsonMap = json.decode(dailySource);
      notifications = Map<int, List<int>>.fromEntries(jsonMap.entries.map(
          (entry) =>
              MapEntry(int.parse(entry.key), List<int>.from(entry.value))));
    }

    if (lateReminders.isNotEmpty) {
      final last = lateReminders.last;

      if (last.hour < 15 && last.hour + 1 < 18) {
        for (final diary in diaries) {
          final diaryID = diary.id;
          // Schedule late afternoon reminders
          // the reminder gets fired randomly between 1pm and 3pm
          final date = diary.start;
          final notificationDate = DateTime(
              date.year, date.month, date.day, last.hour + 1, last.minute);

          final id = Random().nextInt(100000);
          dev.log(
              "Time Scheduled: ${notificationDate.hour}:${notificationDate.minute}",
              name: "Late Afternoon Reminders");
          await NotificationService.createNotification(
              id: id, title: title, body: body, date: notificationDate,  payload: {"type": "reminder"});
          notifications[diaryID]!.add(id);

          await PendoService.track("ScheduleReminder", {
            "status": "scheduled",
            "page": "onboarding",
            "notification_type": "reminder",
            "scheduled_time":
                "${notificationDate.hour}:${notificationDate.minute}",
          });
        }
      }
    } else {
      for (final diary in diaries) {
        // Schedule late afternoon reminders
        // the reminder gets fired randomly between 1pm and 3pm
        final date = diary.start;
        final notificationDate = DateTime(date.year, date.month, date.day,
            Random().nextInt(3) + 13, Random().nextInt(60));

        final id = Random().nextInt(100000);
        await NotificationService.createNotification(
            id: id, title: title, body: body, date: notificationDate,  payload: {"type": "reminder"});
        dev.log(
            "Time Scheduled Else: ${notificationDate.hour}:${notificationDate.minute}",
            name: "Late Afternoon Reminders");
        await PendoService.track("ScheduleReminder", {
          "status": "scheduled",
          "page": "onboarding",
          "notification_type": "reminder",
          "scheduled_time":
              "${notificationDate.hour}:${notificationDate.minute}",
        });
      }
    }
  }
}

///  latestReminderTime: -0001-11-30 16:00:00.000
///I/flutter (17258): reminderTime: 2024-05-23 15:00:00.000

/// Re-schedules all diary-related notifications.
///
/// This function is responsible for re-scheduling all diary-related notifications. It first removes
/// the existing diary notifications stored in the app's preferences. Then, it initializes a new
/// [SetupRepository] and calls its `createNotifications` method to recreate and schedule the
/// diary notifications.
///
/// Usage example:
/// ```dart
/// reScheduleAllNotifications();
/// ```
void reScheduleAllNotifications() async {
  await PreferenceService().removePreference(key: 'diary_notifications');

  final repository = SetupRepository();
  repository.createNotifications(page: "settings");
}
