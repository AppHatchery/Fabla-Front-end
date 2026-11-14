import 'dart:developer';
import 'dart:math' show Random;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Channel for Firebase push messages shown while the app is in the
/// foreground. Registered in [NotificationService.init].
const pushChannelKey = 'high_importance_channel';

/// Handles Firebase Cloud Messaging.
///
/// Push messages that arrive while the app is in the background are shown by
/// the OS. On Android, messages that arrive in the foreground are not, so
/// [messageHandler] shows them through awesome_notifications, the app's only
/// local notification library.
class NotificationsController {
  final FirebaseMessaging _messaging;
  final AwesomeNotifications _notifications;

  NotificationsController({
    FirebaseMessaging? messaging,
    AwesomeNotifications? notifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _notifications = notifications ?? AwesomeNotifications();

  Future<void> initialize() async {
    await _messaging.getInitialMessage();
    FirebaseMessaging.onMessage.listen(messageHandler);
  }

  /// Shows a foreground push message (Android only; iOS foreground display
  /// is governed by FCM's presentation options).
  Future<void> messageHandler(RemoteMessage message) async {
    final notification = message.notification;
    final android = notification?.android;
    if (notification == null || android == null) return;

    final image = android.imageUrl;
    final hasImage = image != null && image.isNotEmpty;
    try {
      await _notifications.createNotification(
        content: NotificationContent(
          id: (message.messageId?.hashCode ?? Random().nextInt(1 << 30)) &
              0x7FFFFFFF,
          channelKey: pushChannelKey,
          title: notification.title,
          body: notification.body,
          // awesome_notifications downloads the image itself and still shows
          // the notification if that fails.
          bigPicture: hasImage ? image : null,
          largeIcon: hasImage ? image : null,
          notificationLayout: hasImage
              ? NotificationLayout.BigPicture
              : NotificationLayout.Default,
        ),
      );
    } catch (e) {
      log('Showing push message failed: $e', name: 'NotificationsController');
    }
  }

  Future<void> requestPermission() async {
    // Updated to use injected messaging instance instead of static FirebaseMessaging.instance
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Updated to use injected messaging instance
      _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> getToken() async {
    // Updated to use injected messaging instance instead of static FirebaseMessaging.instance
    final token = await _messaging.getToken();
    log("Firebase Token: $token");
  }
}
