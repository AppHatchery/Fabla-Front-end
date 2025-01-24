import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class NotificationsController {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  Future<void> initialize() async {
    await FirebaseMessaging.instance.getInitialMessage();
   // await requestPermission();
    await setupNotificationPlugin();
    await getToken();

    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      messageHandler(event);
    });
  }

  Future<void> messageHandler(RemoteMessage message) async {
    final notification = message.notification;
    final androidNotification = notification?.android;

    if (notification != null && androidNotification != null) {
      String? imagePath;
      StyleInformation notificationStyle = const DefaultStyleInformation(true, true);

      if (androidNotification.imageUrl != null &&
          androidNotification.imageUrl!.isNotEmpty) {
        imagePath = await _downloadAndSaveFile(androidNotification.imageUrl!, 'bigPicture');

        notificationStyle = BigPictureStyleInformation(
          FilePathAndroidBitmap(imagePath),
          contentTitle: '<b>${notification.title}</b>',
          htmlFormatContentTitle: true,
          summaryText: '${notification.body}',
          htmlFormatSummaryText: true,
        );
      }

      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // Channel ID
            'High Importance Notifications', // Channel Name
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            styleInformation: notificationStyle,
            largeIcon: imagePath != null ? FilePathAndroidBitmap(imagePath) : null,
          ),
        ),
      );
    }
  }

  Future<void> requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> getToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    log("Firebase Token: $token");
  }

  Future<void> setupNotificationPlugin() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  void onDidReceiveNotificationResponse(NotificationResponse response) async {
    if (response.payload != null) {
      log('Notification payload: ${response.payload}');
    }
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }
}
