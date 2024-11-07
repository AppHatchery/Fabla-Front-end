import 'dart:math';

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/services/notification_service.dart';
import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/services/pendo_service.dart';

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
            .map((e) => DateTime.parse(e.content!.payload!['date']!))
            .toSet(); // Convert to a Set for faster lookup

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
              "scheduled_time":
                  "${notification.date.hour}:${notification.date.minute}",
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
    final diaries = diaryRepository.getAllDiaries();
    int scheduledCount = 0;

    for (final diary in diaries) {
      if (scheduledCount >= threshold) break;

      final diaryNotifications = diary.notifications;

      for (final notification in diaryNotifications) {
        if (scheduledCount >= threshold) break;

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
          "scheduled_time":
              "${notification.date.hour}:${notification.date.minute}",
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
      final payload = notification.content!.payload!;
      dev.log('Notification payload: $payload');
      if (payload['diary'] == id.toString() &&
          notification.content?.id != null) {
        await NotificationService.cancelNotification(notification.content!.id!);
      }
    }
  }

  //TODO: Implement 1. daily goal notifications 2. continue notifications 3. submit diary notifications
}
