import 'dart:math';

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/services/notification_service.dart';
import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:flutter/material.dart' show TimeOfDay;

/// NotificationManager class is responsible for scheduling notifications

/// The threshold is the number of notification allowed to be scheduled at a time
const int threshold = 50;

class NotificationManager {
  final DiaryRepository diaryRepository = DiaryRepository();

  /// Schedule additional notifications
  /// This method schedules additional notifications for diaries that are due
  /// It checks the number of notifications scheduled and schedules more if necessary
  /// It also ensures that notifications are not scheduled more than once
  /// It uses the NotificationService to schedule notifications
  /// It uses the DiaryRepository to get all diaries that are due
  ///
  void scheduleAdditional() async {
    final now = DateTime.now();

    // Get the number of notifications scheduled
    final scheduledNotifications =
        (await NotificationService.getScheduledNotifications())
            .where((e) =>
                e.content?.payload?['date'] != null) // Filter out null payloads
            .map((e) => DateTime.parse(e.content!.payload!['date']!))
            .toSet(); // Convert to a Set for faster lookup

    //track what is scheduled
    await PendoService.track("ScheduledNotifications", {
      "status": "scheduled",
      "page": "home",
      "scheduled_count": scheduledNotifications.length,
    });

    // Get all diaries that are not complete or submitted and due in the future
    final diaries = diaryRepository
        .getAllDiaries()
        .where((diary) =>
            diary.due.isAfter(now) &&
            ![DiaryStatus.complete, DiaryStatus.submitted]
                .contains(diary.status))
        .toList();

    // Check if the number of scheduled notifications is below the threshold
    if (scheduledNotifications.length < threshold) {
      final int notificationsToSchedule =
          threshold - scheduledNotifications.length;
      dev.log(
          'Scheduled Notifications Count: ${scheduledNotifications.length}');
      dev.log('Notifications to schedule: $notificationsToSchedule');

      int scheduledCount = 0;
      List<Future<void>> futures = [];

      // Iterate through each diary to schedule notifications
      for (final diary in diaries) {
        // Stop if the required number of notifications have been scheduled
        if (scheduledCount >= notificationsToSchedule) break;

        // Access the list of notifications from the current diary
        final diaryNotifications = diary.notifications;

        // Iterate through the notifications of the diary
        for (final notification in diaryNotifications) {
          // Stop if the required number of notifications have been scheduled
          if (scheduledCount >= notificationsToSchedule) break;

          // Check if this notification has not already been scheduled
          if (!scheduledNotifications.contains(notification.date) &&
              notification.date.isAfter(now)) {
            // Generate a unique ID for the notification
            final int id = generateUniqueId(diary.id, notification.date);

            // Schedule the notification asynchronously
            futures.add(NotificationService.createNotification(
              id: id,
              title: notification.title,
              body: notification.body,
              date: notification.date,
              payload: {
                'id': id.toString(),
                'date': notification.date.toString(),
                'diary': diary.id.toString(),
              },
            ));

            await PendoService.track("ScheduleReminder", {
              "status": "scheduled",
              "page": "home",
              "notification_type": "reminder",
              "notification_id": id,
              "content":
                  "Title: ${notification.title}, Body: ${notification.body}",
              "scheduled_time": notification.date.toIso8601String(),
              "scheduled_count": scheduledCount
            });

            dev.log(
                'Scheduling notification - id: $id, title: ${notification.title}, body: ${notification.body}, date: ${notification.date}');

            // Increment the count of scheduled notifications
            scheduledCount++;
          }
        }
      }

      // Wait for all notifications to be scheduled
      await Future.wait(futures);
    }
  }

// Utility function to generate unique notification IDs
  int generateUniqueId(int diaryId, DateTime date) {
    return diaryId.hashCode ^ date.hashCode; // Simple hash-based unique ID
  }

  /// Schedule the first fifty notifications
  /// This method schedules the first fifty notifications for diaries that are due
  /// It uses the NotificationService to schedule notifications
  /// It uses the DiaryRepository to get all diaries that are due
  /// It schedules notifications for diaries that are due and have not been scheduled
  /// It schedules notifications for the limit set at [threshold]
  void scheduleLimit() async {
    // clear all notifications
    await NotificationService.cancelAllNotifications();

    final diaries = diaryRepository.getAllDiaries();
    int scheduledCount = 0;

    for (final diary in diaries) {
      if (scheduledCount >= threshold) break;

      final diaryNotifications = diary.notifications;

      for (final notification in diaryNotifications) {
        if (scheduledCount >= threshold) break;

        // Skip if notification is not valid/able to fire
        final isValidNotification = notification.date.isAfter(DateTime.now());
        if (!isValidNotification) continue;

        final int id = Random().nextInt(100000);

        dev.log(
            'Scheduling notification - id: $id, title: ${notification.title}, body: ${notification.body}, date: ${notification.date}');

        await NotificationService.createNotification(
          id: id,
          title: notification.title,
          body: notification.body,
          date: notification.date,
          payload: {
            'id': id.toString(),
            'date': notification.date.toString(),
            'diary': diary.id.toString(),
          },
        );
        await PendoService.track("ScheduleReminder", {
          "status": "scheduled",
          "page": "onboarding",
          "notification_type": "reminder",
          "notification_id": id,
          "content":
              "Diary: ${diary.name}, Title: ${notification.title}, Body: ${notification.body}",
          "scheduled_time": notification.date.toIso8601String(),
          "scheduled_count": scheduledCount,
        });

        scheduledCount++;
      }
    }
    dev.log('Scheduled $scheduledCount notifications');
  }

  /// Cancel diary notifications
  /// This method cancels all notifications for a diary
  /// It uses the NotificationService to cancel notifications
  /// It cancels notifications for a diary with the specified ID
  void cancelDiaryNotifications(int id) async {
    dev.log('Cancelling notifications for diary $id');
    final notifications = await NotificationService.getScheduledNotifications();
    for (final notification in notifications) {
      final payload = notification.content!.payload;
      dev.log('Notification payload: $payload');
      if (payload?['diary'] == id.toString() &&
          notification.content?.id != null) {
        await NotificationService.cancelNotification(notification.content!.id!);
      }
    }
  }

  //TODO: Implement 1. daily goal notifications 2. continue notifications 3. submit diary notifications

  /// Only schedule 7 user reminders and only on days that have diaries
  /// The payload will contain the date of the reminder and type of reminder
  void scheduleUserReminders() async {
    // Get user's preferred reminder times from saved preferences
    final timesFromString = await PreferenceService()
        .getStringListPreference(key: 'reminder_times');
    final times = timesFromString
            ?.map((e) => TimeOfDay.fromDateTime(DateTime.parse(e)))
            .toList() ??
        [];
    if (times.isEmpty) {
      dev.log('No reminder times set by user, skipping scheduling reminders.');
      return;
    }

    final limit = 7;
    final now = DateTime.now();
    final scheduledNotifications =
        (await NotificationService.getScheduledNotifications())
            .where((e) =>
                e.content?.payload?['date'] != null &&
                e.content?.payload?['type'] == 'reminder')
            .map((e) => DateTime.parse(e.content!.payload!['date']!))
            .toSet();

    if (scheduledNotifications.length >= limit) {
      dev.log(
          'User reminders already scheduled: ${scheduledNotifications.length}');
      return;
    }

    final int notificationsToSchedule = limit - scheduledNotifications.length;

    // Get all diaries and filter only those due in the future
    final diaries = diaryRepository.getEveryDiary();
    final filteredDiaries = diaries
        .where((diary) => diary.due.isAfter(now))
        .map((d) => DateTime(d.due.year, d.due.month, d.due.day))
        .toSet();

    times.sort((a, b) =>
        (a.hour + a.minute / 60.0).compareTo(b.hour + b.minute / 60.0));

    int scheduledCount = 0;
    int dayOffset = 0;

    // Look ahead up to 30 days to find valid dates with diaries
    while (scheduledCount < notificationsToSchedule && dayOffset < 30) {
      final reminderDate =
          DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
      dayOffset++; // Always move to next day

      if (!filteredDiaries.contains(reminderDate)) continue;
      if (scheduledNotifications.contains(reminderDate)) continue;

      final scheduledDateTime = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        times.first.hour,
        times.first.minute,
      );

      if (scheduledDateTime.isBefore(now)) continue; // Skip past dates

      final id = Random().nextInt(100000);
      await NotificationService.createNotification(
        id: id,
        title: 'Daily Reminder',
        body: 'Time to check your Fabla entries!',
        date: scheduledDateTime,
        payload: {
          'id': id.toString(),
          'date': reminderDate.toIso8601String(),
          'type': 'reminder',
        },
      );
      dev.log('Scheduled user reminder - id: $id, date: $scheduledDateTime');

      scheduledCount++;
    }
  }

  void removeUserReminders() async {
    final scheduledNotifications =
        (await NotificationService.getScheduledNotifications())
            .where((e) =>
                e.content?.payload?['date'] != null &&
                e.content?.payload?['type'] == 'reminder')
            .toList();

    for (final notification in scheduledNotifications) {
      if (notification.content?.id != null) {
        await NotificationService.cancelNotification(notification.content!.id!);
      }
    }
  }
}
