import 'dart:convert';
import 'dart:math';

import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';

import '../../services/notification_service.dart';
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

/// Schedules or reschedules a "Continue Diary" notification for a specific diary with the given [id].
///
/// This function is responsible for scheduling or rescheduling a "Continue Diary" notification for a
/// particular item identified by its [id]. It first retrieves the existing diary notifications from
/// the app's preferences, checks for notifications related to the provided [id], and cancels any existing
/// notifications for that item. Then, it calculates the appropriate time for the new notification,
/// creates the notification using the [NotificationService], and updates the stored notifications information
/// in the preferences.
///
/// Parameters:
/// - [id]: The identifier of the item for which a "Continue Diary" notification should be scheduled.
///
/// Usage example:
/// ```dart
/// scheduleContinueDiaryNotifications(123);
/// ```
void scheduleContinueDiaryNotifications(int id) async {
  final source =
      await PreferenceService().getStringPreference(key: 'diary_notifications');

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
      for (int notification in notificationsForId) {
        await NotificationService.cancelNotification(notification);
      }
      notificationsForId.clear();

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day, 23, 59);
      final difference = midnight.difference(now);

      final dates = (difference.inHours > 6 &&
              now.isAfter(DateTime(now.year, now.month, now.day, 4, 0))
          ? [
              now.add(const Duration(hours: 6)),
              now.add(const Duration(minutes: 30))
            ]
          : [now.add(const Duration(minutes: 30))]);

      for (final date in dates) {
        final notificationID = Random().nextInt(100000);

        final body = dates.length > 1 && dates.indexOf(date) == 0
            ? "Only a few hours left to finish! Make sure to get your diary in before you go to sleep."
            : "Don't forget to continue where you left off. We appreciate your input!";

        await NotificationService.createNotification(
            id: notificationID,
            title: 'Time to Continue Your Diary!',
            body: body,
            date: date);

        notifications[id]!.add(notificationID);
      }

      final updatedJsonMap = Map<String, dynamic>.fromEntries(notifications
          .entries
          .map((entry) => MapEntry(entry.key.toString(), entry.value)));

      final encoded = json.encode(updatedJsonMap);
      await PreferenceService()
          .setStringPreference(key: 'diary_notifications', value: encoded);
    }
  }
}

/// Schedules or reschedules a "Submit Diary" notification for a specific diary with the given [id].
///
/// This function is responsible for scheduling or rescheduling a "Submit Diary" notification for a
/// particular item identified by its [id]. It first retrieves the existing diary notifications from
/// the app's preferences, checks for notifications related to the provided [id], and cancels any existing
/// notifications for that item. Then, it calculates the appropriate time for the new notification,
/// creates the notification using the [NotificationService], and updates the stored notifications information
/// in the preferences.
///
/// Parameters:
/// - [id]: The identifier of the item for which a "Submit Diary" notification should be scheduled.
///
/// Usage example:
/// ```dart
/// scheduleSubmitDiaryNotification(123);
/// ```
void scheduleSubmitDiaryNotification(int id) async {
  final source =
      await PreferenceService().getStringPreference(key: 'diary_notifications');

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
      for (int notification in notificationsForId) {
        await NotificationService.cancelNotification(notification);
      }
      notificationsForId.clear();

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day, 23, 59);
      final difference = midnight.difference(now);

      final dates = (difference.inHours > 6 &&
              now.isAfter(DateTime(now.year, now.month, now.day, 4, 0))
          ? [
              now.add(const Duration(hours: 6)),
              now.add(const Duration(minutes: 30))
            ]
          : [now.add(const Duration(minutes: 30))]);

      for (final date in dates) {
        final notificationID = Random().nextInt(100000);

        await NotificationService.createNotification(
            id: notificationID,
            title: 'Your Diary Is Ready for Submission!',
            body:
                "You've completed your diary. Fantastic! Just one more step: hit 'Submit' to share your valuable thoughts.",
            date: date);

        notifications[id]!.add(notificationID);
      }

      final updatedJsonMap = Map<String, dynamic>.fromEntries(notifications
          .entries
          .map((entry) => MapEntry(entry.key.toString(), entry.value)));

      final encoded = json.encode(updatedJsonMap);
      await PreferenceService()
          .setStringPreference(key: 'diary_notifications', value: encoded);
    }
  }
}

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
  repository.createNotifications();
}
