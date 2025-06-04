import 'dart:io';
import 'package:audio_diaries_flutter/core/notifications/controllers/notifications_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../../../firebase_mock.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockHttpClient extends Mock implements http.Client {}

class MockDirectory extends Mock implements Directory {}

class MockFile extends Mock implements File {}

void main() {
  late NotificationsController controller;
  late MockFirebaseMessaging mockFirebaseMessaging;
  late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
  late MockHttpClient mockHttpClient;
  late MockDirectory mockDirectory;
  late MockFile mockFile;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupFirebaseMocks();

    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '/test/path';
      }
      return null;
    });

    const MethodChannel('dexterous.com/flutter_local_notifications')
        .setMockMethodCallHandler((MethodCall methodCall) async => null);

    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(
        const AndroidInitializationSettings('@mipmap/ic_launcher'));
    registerFallbackValue(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    registerFallbackValue(NotificationDetails(
      android: AndroidNotificationDetails('channelId', 'channelName'),
    ));
  });

  setUp(() {
    mockFirebaseMessaging = MockFirebaseMessaging();
    mockLocalNotifications = MockFlutterLocalNotificationsPlugin();
    mockHttpClient = MockHttpClient();
    mockDirectory = MockDirectory();
    mockFile = MockFile();

    controller = NotificationsController(messaging: mockFirebaseMessaging);
    controller.flutterLocalNotificationsPlugin = mockLocalNotifications;
  });

  group('NotificationsController Tests', () {
    test('initialize sets up Firebase messaging and notifications', () async {
      when(() => mockFirebaseMessaging.getInitialMessage())
          .thenAnswer((_) async => null);

      when(() => mockLocalNotifications.initialize(
            any(),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).thenAnswer((_) async => true);

      await controller.initialize();

      verify(() => mockFirebaseMessaging.getInitialMessage()).called(1);
      verify(() => mockLocalNotifications.initialize(
            any(),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).called(1);
    });

    test('messageHandler shows notification with image', () async {
      const imageUrl = 'https://example.com/image.jpg';
      const title = 'Test Title';
      const body = 'Test Body';

      final message = RemoteMessage(
        notification: RemoteNotification(
          title: title,
          body: body,
          android: AndroidNotification(imageUrl: imageUrl),
        ),
      );

      when(() => getApplicationDocumentsDirectory())
          .thenAnswer((_) async => mockDirectory);
      when(() => mockDirectory.path).thenReturn('/test/path');
      when(() => mockFile.writeAsBytes(any()))
          .thenAnswer((_) async => mockFile);
      when(() => mockFile.path).thenReturn('/test/path/image.jpg');
      when(() => mockLocalNotifications.show(any(), any(), any(), any()))
          .thenAnswer((_) async => {});

      await controller.messageHandler(message);

      verify(() => mockLocalNotifications.show(
            any(),
            title,
            body,
            any(),
          )).called(1);
    });

    test('requestPermission requests notification permissions', () async {
      when(() => mockFirebaseMessaging.requestPermission(
            alert: any(named: 'alert'),
            announcement: any(named: 'announcement'),
            badge: any(named: 'badge'),
            carPlay: any(named: 'carPlay'),
            criticalAlert: any(named: 'criticalAlert'),
            provisional: any(named: 'provisional'),
            sound: any(named: 'sound'),
          )).thenAnswer((_) async => NotificationSettings(
            authorizationStatus: AuthorizationStatus.authorized,
            alert: AppleNotificationSetting.enabled,
            announcement: AppleNotificationSetting.disabled,
            badge: AppleNotificationSetting.enabled,
            carPlay: AppleNotificationSetting.disabled,
            lockScreen: AppleNotificationSetting.enabled,
            notificationCenter: AppleNotificationSetting.enabled,
            showPreviews: AppleShowPreviewSetting.always,
            timeSensitive: AppleNotificationSetting.enabled,
            criticalAlert: AppleNotificationSetting.enabled,
            sound: AppleNotificationSetting.enabled,
            providesAppNotificationSettings: AppleNotificationSetting.enabled,
          ));

      when(() =>
          mockFirebaseMessaging.setForegroundNotificationPresentationOptions(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
          )).thenAnswer((_) async => {});

      await controller.requestPermission();

      verify(() => mockFirebaseMessaging.requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: true,
            provisional: false,
            sound: true,
          )).called(1);

      verify(() =>
          mockFirebaseMessaging.setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          )).called(1);
    });

    test('getToken retrieves Firebase token', () async {
      const token = 'test-token';
      when(() => mockFirebaseMessaging.getToken())
          .thenAnswer((_) async => token);

      await controller.getToken();

      verify(() => mockFirebaseMessaging.getToken()).called(1);
    });

    test('setupNotificationPlugin initializes local notifications', () async {
      when(() => mockLocalNotifications.initialize(
            any(),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).thenAnswer((_) async => true);

      await controller.setupNotificationPlugin();

      verify(() => mockLocalNotifications.initialize(
            any(),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).called(1);
    });

    test('onDidReceiveNotificationResponse handles notification response',
        () async {
      const payload = 'test-payload';
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      controller.onDidReceiveNotificationResponse(response);
    });
  });
}
