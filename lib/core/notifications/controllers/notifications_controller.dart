import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Controller for handling Firebase Cloud Messaging and local notifications.
///
/// This class manages:
/// - Firebase Cloud Messaging initialization and message handling
/// - Local notification setup and display
/// - Notification permissions
/// - Token management
///
/// For testing purposes, this class accepts a [FirebaseMessaging] instance,
/// [FlutterLocalNotificationsPlugin] instance, and [http.Client] instance
/// to allow dependency injection and mocking.
class NotificationsController {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final FirebaseMessaging _messaging;
  final http.Client _httpClient;

  /// Creates a new [NotificationsController].
  ///
  /// [messaging] is optional and defaults to [FirebaseMessaging.instance].
  /// [localNotifications] is optional and defaults to a new [FlutterLocalNotificationsPlugin] instance.
  /// [client] is optional and defaults to a new [http.Client] instance.
  /// This allows for dependency injection during testing.
  NotificationsController({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    http.Client? client,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        flutterLocalNotificationsPlugin =
            localNotifications ?? FlutterLocalNotificationsPlugin(),
        _httpClient = client ?? http.Client();

  Future<void> initialize() async {
    await _messaging.getInitialMessage();
    // await requestPermission();
    await setupNotificationPlugin();
    //await getToken();

    // Note: onMessage is a static stream, so we can't use the instance
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      messageHandler(event);
    });
  }

  Future<void> messageHandler(RemoteMessage message) async {
    final notification = message.notification;
    final androidNotification = notification?.android;

    if (notification != null && androidNotification != null) {
      String? imagePath;
      StyleInformation notificationStyle =
          const DefaultStyleInformation(true, true);

      if (androidNotification.imageUrl != null &&
          androidNotification.imageUrl!.isNotEmpty) {
        imagePath = await _downloadAndSaveFile(
            androidNotification.imageUrl!, 'bigPicture');

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
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            styleInformation: notificationStyle,
            largeIcon:
                imagePath != null ? FilePathAndroidBitmap(imagePath) : null,
          ),
        ),
      );
    }
  }

  Future<void> requestPermission() async {
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
      _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> getToken() async {
    final token = await _messaging.getToken();
    log("Firebase Token: $token");
  }

  Future<void> setupNotificationPlugin() async {
    // flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin(); // Removed this line

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
    final http.Response response =
        await _httpClient.get(Uri.parse(url)); // Use injected client
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }
}
