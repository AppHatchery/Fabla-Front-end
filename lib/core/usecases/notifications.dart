import 'dart:convert';
import 'dart:math';

import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';

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
  final source = await PreferenceService()
      .getStringPreference(key: 'continue_notifications');

  Map<int, List<int>> notifications;
  notifications = {};
  if (source == null) {
    final now = DateTime.now();
    final sevenPM = DateTime(now.year, now.month, now.day, 19);

    DateTime reminderTime;

    if (now.isBefore(sevenPM)) {
      reminderTime = now.add(const Duration(minutes: 30));
    } else {
      return;
    }

    final notificationID = Random().nextInt(100000);
    await NotificationService.createNotification(
        id: notificationID,
        title: 'Time to Continue Your Diary!',
        body:
            "Don't forget to continue where you left off. We appreciate your input!",
        date: reminderTime);

    notifications[id] = [notificationID];

    await PendoService.track("ScheduleReminder", {
      "page": "diary",
      "scheduled_by": "auto",
      "notification_type": "continue",
      "number_of_reminders": 1,
      "reminder_times": "${reminderTime.hour}:${reminderTime.minute}",
    });

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
        final sevenPM = DateTime(now.year, now.month, now.day, 19);

        DateTime reminderTime;

        if (now.isBefore(sevenPM)) {
          reminderTime = now.add(const Duration(minutes: 30));
        } else {
          return;
        }

        final notificationID = Random().nextInt(100000);
        await NotificationService.createNotification(
            id: notificationID,
            title: 'Time to Continue Your Diary!',
            body:
                "Don't forget to continue where you left off. We appreciate your input!",
            date: reminderTime);

        notifications[id] = [notificationID];

        await PendoService.track("ScheduleReminder", {
          "page": "diary",
          "scheduled_by": "auto",
          "notification_type": "continue",
          "number_of_reminders": 1,
          "reminder_times": "${reminderTime.hour}:${reminderTime.minute}",
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
          date: reminderTime);

      notifications[id] = [notificationID];

      await PendoService.track("ScheduleReminder", {
        "page": "summary",
        "scheduled_by": "auto",
        "notification_type": "submit",
        "number_of_reminders": 1,
        "reminder_times": "${reminderTime.hour}:${reminderTime.minute}",
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
void dailyGoalNotification(int id) async {
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
          await NotificationService.cancelNotification(notification);
        }
      }
    }
    final notificationID = Random().nextInt(100000);
    await NotificationService.createNotification(
        id: notificationID,
        title: 'You still have time to accomplish your goal!',
        body: 'You have not yet reached your daily goal. Keep going!',
        date: potential);

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
/// This function calculates the next notification time, defaulting to 3 PM today if no previous time is given,
/// and ensuring the time is within the bounds of 3 PM and 7 PM on the current day.
///
/// Parameters:
/// - [last]: The DateTime object representing the last notification time, or null if there was no previous notification.
///
/// Returns:
/// A DateTime object representing the next notification time, or null if the conditions are not met.
DateTime? retrieveNotificationDate(DateTime? last) {
  // Check if the last notification time is null
  if (last == null) {
    // If last is null, return 3 PM of the current day
    return DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day, 15);
  } else {
    // Get the current date and time
    final now = DateTime.now();
    // Define 3 PM and 7 PM of the current day
    final threePM = DateTime(now.year, now.month, now.day, 15); // 3 PM today
    final sevenPM = DateTime(now.year, now.month, now.day, 19); // 7 PM today

    // Calculate one hour after the last notification time on the current day
    final oneHourLater =
        DateTime(now.year, now.month, now.day, last.hour, last.minute)
            .add(const Duration(hours: 1));

    // Get the actual reminder time based on the last notification time on the current day
    final actualReminderTime =
        DateTime(now.year, now.month, now.day, last.hour, last.minute);

    // Declare a variable to hold the calculated reminder time
    late DateTime reminderTime;

    // Determine the reminder time based on whether it is before or after 3 PM
    if (actualReminderTime.isBefore(threePM)) {
      // If the actual reminder time is before 3 PM
      reminderTime =
          threePM.isBefore(now) ? now.add(const Duration(hours: 1)) : threePM;
    } else if ((actualReminderTime.isAtSameMomentAs(threePM) ||
        actualReminderTime.isAfter(threePM))) {
      // If the actual reminder time is at the same moment or after 3 PM
      reminderTime = now.isAfter(actualReminderTime)
          ? now.add(const Duration(hours: 1))
          : oneHourLater;
    }

    // Check if the reminder time is before 7 PM and return it if true
    if (reminderTime.isBefore(sevenPM)) {
      return reminderTime;
    }
  }
  // Return null if none of the conditions are met
  return null;
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
