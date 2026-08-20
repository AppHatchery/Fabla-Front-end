import 'dart:math';

import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../theme/custom_colors.dart';

class NotificationService {
  /// if channel is disabled show the user a card
  static final ValueNotifier<bool> channelDisabled = ValueNotifier<bool>(false);

  /// Static instance of AwesomeNotifications for dependency injection.
  /// Can be overridden for testing purposes.
  static AwesomeNotifications _awesomeNotifications = AwesomeNotifications();

  /// Opens the system settings page for the audio-diaries channel.
  /// Bind this to the "Open Settings" button on NoNotificationCard.
  static Future<void> openChannelSettings() async {
    await _awesomeNotifications.showNotificationConfigPage(
        channelKey: 'audio-diaries');
  }

  /// Sets a custom AwesomeNotifications instance for testing.
  /// This method allows tests to inject a mock instance.
  static void setAwesomeNotificationsForTesting(AwesomeNotifications instance) {
    _awesomeNotifications = instance;
  }

  /// Resets the AwesomeNotifications instance to the default.
  /// Used to clean up after tests.
  static void resetAwesomeNotifications() {
    _awesomeNotifications = AwesomeNotifications();
  }

  /// Initializes the notification system with custom notification channels.
  ///
  /// This function sets up the notification system using the AwesomeNotifications package.
  /// It initializes the notification system with custom notification channels, each
  /// representing a distinct category of notifications. You can configure channel-specific
  /// properties such as name, description, color, and importance. The function should
  /// be called at the start of the application to properly configure the notification system.
  ///
  /// Example usage:
  /// ```dart
  /// NotificationService.init(); // Initialize the notification system with custom channels.
  /// ```
  static Future<void> init() async {
    await _awesomeNotifications.initialize(
        null,
        [
          NotificationChannel(
              channelKey: "audio-diaries",
              channelName: "Fabla",
              channelDescription: "Reminders for Daily Diary Entries",
              channelShowBadge: false,
              defaultColor: CustomColors.fillWhite,
              playSound: true,
              enableVibration: true,
              importance: NotificationImportance.Max)
        ],
        debug: true);
  }

  /// Sets up listeners to handle notification actions and dismiss actions.
  ///
  /// This function configures the listeners for handling notification actions
  /// (e.g., button taps) and dismiss actions (when the user dismisses a notification).
  /// These callback methods define the custom
  /// behavior to be executed when the corresponding actions are performed by the user.
  ///
  /// Note: Ensure that the `onActionReceivedMethod` and `onDismissActionReceivedMethod`
  /// functions are defined before calling this function.
  static Future<void> setListeners() async =>
      await _awesomeNotifications.setListeners(
          onActionReceivedMethod: onActionReceivedMethod,
          onDismissActionReceivedMethod: onDismissActionReceivedMethod);

  /// Callback method invoked when an action associated with a notification is received.
  ///
  /// This method is marked with the @pragma("vm:entry-point") directive, indicating
  /// that it is an entry point for the Dart Virtual Machine (VM). It is invoked when
  /// a user interacts with a notification by performing an action, such as tapping
  /// a button. You can implement custom behavior here to handle the specific action,
  /// such as navigating to a certain screen, updating data, or performing any other
  /// desired action.
  ///
  /// Parameters:
  /// - [receivedAction]: The received action associated with the user's interaction.
  ///   It contains information about the action, including its key and payload.
  ///
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    await PendoService.track('ScheduleReminder', {
      "status": "opened",
      "page": "N/A",
      "notification_type": receivedAction.payload?['type'],
      "scheduled_time":
          "${receivedAction.displayedDate?.hour}:${receivedAction.displayedDate?.minute}"
    });
    debugPrint("Payload: ${receivedAction.payload}");
  }

  /// Callback method invoked when a dismiss action is received for a notification.
  ///
  /// This method is marked with the @pragma("vm:entry-point") directive, indicating
  /// that it is an entry point for the Dart Virtual Machine (VM). It is invoked when
  /// a user dismisses a notification that has a dismiss action associated with it.
  /// You can implement custom behavior here, such as handling cleanup or logging
  /// when a notification is dismissed by the user.
  ///
  /// Parameters:
  /// - [receivedAction]: The received action associated with the dismiss action.
  ///   It contains information about the action, including its key and payload.
  ///
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    await PendoService.track('ScheduleReminder', {
      "status": "dismissed",
      "page": "N/A",
      "notification_type": receivedAction.payload?['type'],
      "scheduled_time":
          "${receivedAction.displayedDate?.hour}:${receivedAction.displayedDate?.minute}"
    });
    debugPrint("Notification Dismissed");
  }

  /// Callback method invoked when a notification is displayed to the user.
  ///
  /// This method is marked with the @pragma("vm:entry-point") directive, indicating
  /// that it is an entry point for the Dart Virtual Machine (VM). It is invoked when
  ///
  /// Parameters:
  /// - [receivedNotification]: The received notification that was displayed.
  ///  It contains information about the notification, including its payload and displayed date.
  ///
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    final date = receivedNotification.displayedDate?.toLocal();
    await PendoService.track('ScheduleReminder', {
      "status": "fired",
      "page": "N/A",
      "notification_type": receivedNotification.payload?['type'],
      "scheduled_time": "${date?.hour}:${date?.minute}"
    });
    debugPrint(
        "Notification Displayed with payload: ${receivedNotification.payload}");
  }

  /// Creates a notification with the provided title, body, and scheduled date.
  ///
  /// It checks if the app has permission to show notifications. If permission is granted,
  /// the function generates a unique notification ID and configures the notification content,
  /// action buttons, and schedule. The notification is then created and scheduled.
  ///
  /// If permission is not granted, the function returns `false`.
  ///
  /// Parameters:
  /// - [id]: The unique identifier of the scheduled notification
  /// - [title]: The title of the notification.
  /// - [body]: The body of the notification.
  /// - [date]: The date at which the notification should be scheduled.
  /// - [payload]: An optional payload associated with the notification.
  ///
  /// Returns:
  /// - `true` if the notification was successfully created and scheduled.
  /// - `false` if the app does not have permission to show notifications.
  ///
  /// Example usage:
  /// ```dart
  /// bool isNotificationCreated = await NotificationService.createNotification(
  ///   title: 'Daily Diary',
  ///   body: "Don't forget to record your daily diary today",
  ///   date: DateTime(2023, 8, 30, 15, 0), // August 30, 2023, 3:00 PM
  /// );
  /// ```
  static Future<bool> createNotification(
      {final int? id,
      required final String title,
      required final String body,
      required final DateTime date,
      Map<String, String>? payload}) async {
    //checks if permission for both global and channel are allowed
    final hasPermission = await _awesomeNotifications.isNotificationAllowed();
    if (!hasPermission) {
      channelDisabled.value = true;
      return false;
    }

    try {
      final created = await _awesomeNotifications.createNotification(
          content: NotificationContent(
              id: id ?? Random().nextInt(100000),
              channelKey: 'audio-diaries',
              title: title,
              body: body,
              icon: null,
              largeIcon: null,
              bigPicture: null,
              category: NotificationCategory.Message,
              actionType: ActionType.Default,
              payload: payload),
          actionButtons: [
            NotificationActionButton(key: 'REDIRECT', label: 'Redirect'),
            NotificationActionButton(
                key: 'DISMISS',
                label: 'Dismiss',
                actionType: ActionType.DismissAction,
                isDangerousOption: true)
          ],
          schedule:
              NotificationCalendar.fromDate(date: date, preciseAlarm: true));

      // Success resets the flag so the card disappears.
      if (channelDisabled.value) channelDisabled.value = false;
      return created;
    } on PlatformException catch (e) {
      // Channel disabled, removed, or not yet registered in this isolate.
      debugPrint(
          'createNotification failed: code=${e.code} message=${e.message}');
      channelDisabled.value = true;
      return false;
    }
  }

  /// Displays a notification immediately. Background uploads use this after
  /// the server has accepted the diary, so the user gets confirmation without
  /// reopening Fabla.
  static Future<bool> showImmediateNotification({
    required final int id,
    required final String title,
    required final String body,
    Map<String, String>? payload,
  }) async {
    final hasPermission = await _awesomeNotifications.isNotificationAllowed();
    if (!hasPermission) {
      channelDisabled.value = true;
      return false;
    }

    try {
      final created = await _awesomeNotifications.createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'audio-diaries',
          title: title,
          body: body,
          category: NotificationCategory.Status,
          actionType: ActionType.Default,
          payload: payload,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
      );
      if (channelDisabled.value) channelDisabled.value = false;
      return created;
    } on PlatformException catch (e) {
      debugPrint(
          'showImmediateNotification failed: code=${e.code} message=${e.message}');
      channelDisabled.value = true;
      return false;
    }
  }

  /// Cancels all scheduled and active notifications.
  ///
  /// This function cancels all scheduled
  /// and active notifications. It stops any pending or ongoing notifications from
  /// being displayed or triggered. Calling this function can be useful when you
  /// want to clear the notification queue or remove all notifications at once.
  ///
  /// Example usage:
  /// ```dart
  /// NotificationService.cancelAllNotifications(); // Cancel all scheduled and active notifications.
  /// ```
  static Future<void> cancelAllNotifications() async =>
      await _awesomeNotifications.cancelAll();

  /// Cancels a scheduled notification with the specified [id].
  ///
  /// This function allows you to programmatically cancel a previously scheduled
  /// notification using its unique identifier [id]. It utilizes the
  /// `AwesomeNotifications` library to perform the cancellation.
  ///
  /// Parameters:
  ///   - [id]: The unique identifier of the scheduled notification to be canceled.
  ///
  /// Usage Example:
  /// ```dart
  /// await cancelNotification(123); // Cancels the notification with ID 123.
  /// ```
  ///
  /// Note: This function is asynchronous, so it should be awaited when called.

  static Future<void> cancelNotification(int id) async =>
      await _awesomeNotifications.cancel(id);

  /// Reschedules a notification with updated information.
  ///
  /// This function allows you to reschedule a notification with new title, body,
  /// and date. The function cancels the existing scheduled notification with
  /// the specified [id] and then creates a new notification using the provided
  /// [title], [body], [date], and [payload] information. The notification is
  /// rescheduled to the updated date.
  ///
  /// Parameters:
  /// - [id]: The unique identifier of the notification to be rescheduled.
  /// - [title]: The new title of the notification.
  /// - [body]: The new body of the notification.
  /// - [date]: The new date at which the notification should be rescheduled.
  /// - [payload]: An optional updated payload associated with the notification.
  ///
  /// Returns:
  /// - `true` if the notification was successfully rescheduled.
  /// - `false` if the app does not have permission to show notifications.
  ///
  /// Example usage:
  /// ```dart
  /// bool isRescheduled = await NotificationService.rescheduleNotification(
  ///   id: 12345,
  ///   title: 'Continue Your Daily Diary',
  ///   body: "Don't forget to complete your daily diary today",
  ///   date: DateTime(2023, 8, 30, 16, 0), // August 30, 2023, 4:00 PM
  /// );
  /// ```
  static Future<bool> rescheduleNotification(
      {required final int id,
      required final String title,
      required final String body,
      required final DateTime date,
      Map<String, String>? payload}) async {
    await _awesomeNotifications.cancelSchedule(id);

    return await createNotification(
        title: title, body: body, date: date, payload: payload);
  }

  /// Retrieves a list of all scheduled notifications.
  /// This function returns a list of all scheduled notifications using the
  /// `AwesomeNotifications` library.
  ///
  /// Returns:
  /// A list of scheduled notifications.
  static Future<List<NotificationModel>> getScheduledNotifications() async {
    final scheduledNotifications =
        await _awesomeNotifications.listScheduledNotifications();
    return scheduledNotifications;
  }
}
