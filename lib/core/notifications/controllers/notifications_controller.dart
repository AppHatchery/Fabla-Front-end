import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class NotificationsController {
  // Modified to support dependency injection for better testability
  // Added constructor parameters for messaging, local notifications, and http client
  // Default values maintain backward compatibility
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final FirebaseMessaging _messaging;
  final http.Client _client;

  // Constructor with optional dependency injection
  // If not provided, uses default implementations for production use
  NotificationsController({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    http.Client? client,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _client = client ?? http.Client() {
    // Initialize the local notifications plugin with injected or default instance
    flutterLocalNotificationsPlugin =
        localNotifications ?? FlutterLocalNotificationsPlugin();
  }

  Future<void> initialize() async {
    // Updated to use injected messaging instance instead of static FirebaseMessaging.instance
    await _messaging.getInitialMessage();
    // await requestPermission();
    await setupNotificationPlugin();
    //await getToken();

    // Note: onMessage is a static property so we use FirebaseMessaging.onMessage
    // but we can still use the injected messaging instance for other methods
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
        id: message.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails:  NotificationDetails(
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

  Future<void> setupNotificationPlugin() async {
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
    await flutterLocalNotificationsPlugin.initialize(settings:  initializationSettings,
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
    // Updated to use injected http client instead of static http.get
    final http.Response response = await _client.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }
}
