import 'dart:io';
import 'package:audio_diaries_flutter/core/notifications/controllers/notifications_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:flutter/services.dart';
import '../../../firebase_mock.dart';
import '../../../dummy_data.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockHttpClient extends Mock implements http.Client {}

class MockDirectory extends Mock
    implements
        Directory {} 

class MockFile extends Mock implements File {}

void main() {
  late NotificationsController controller;
  late MockFirebaseMessaging mockFirebaseMessaging;
  late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
  late MockHttpClient mockHttpClient;
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

    registerFallbackValue(Uri.parse(TestValues.testUrl));
    registerFallbackValue(
        const AndroidInitializationSettings('@mipmap/ic_launcher'));
    registerFallbackValue(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    registerFallbackValue(NotificationDetails(
      android: AndroidNotificationDetails('channelId', 'channelName'),
    ));
    registerFallbackValue(FileMode.write);
  });

  setUp(() {
    mockFirebaseMessaging = MockFirebaseMessaging();
    mockLocalNotifications = MockFlutterLocalNotificationsPlugin();
    mockHttpClient = MockHttpClient();

    mockFile = MockFile();

    controller = NotificationsController(
      messaging: mockFirebaseMessaging,
      localNotifications: mockLocalNotifications,
      client: mockHttpClient,
    );
  });

  group('NotificationsController Tests', () {
    test('initialize sets up Firebase messaging and notifications', () async {
      when(() => mockFirebaseMessaging.getInitialMessage())
          .thenAnswer((_) async => null);

      when(() => mockLocalNotifications.initialize(
            settings: any(named: 'settings'),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).thenAnswer((_) async => true);

      await controller.initialize();

      verify(() => mockFirebaseMessaging.getInitialMessage()).called(1);
      verify(() => mockLocalNotifications.initialize(
            settings: any(named: 'settings'),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).called(1);
    });

    test('messageHandler shows notification with image', () async {
      var imageUrl = TestValues.testImagePath;
      const title = TestValues.testName;
      const body = TestValues.testResponse;
      var expectedImagePath = TestValues.testImagePath;

      final message = RemoteMessage(
        notification: RemoteNotification(
          title: title,
          body: body,
          android: AndroidNotification(imageUrl: imageUrl),
        ),
      );

      // Mock for http.get call
      when(() => mockHttpClient.get(Uri.parse(imageUrl))).thenAnswer(
          (_) async => http.Response('fake_image_bytes', 200,
              headers: {'content-type': 'image/jpeg'}));

      // Configure mockFile instance
      when(() => mockFile.path).thenReturn(expectedImagePath);
      when(() => mockFile.writeAsBytes(
            any(that: isA<List<int>>()),
            mode: any(named: 'mode', that: isA<FileMode>()),
            flush: any(named: 'flush', that: isA<bool>()),
          )).thenAnswer((_) async => mockFile);

      when(() => mockLocalNotifications.show(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            notificationDetails: any(named: 'notificationDetails'),
          )).thenAnswer((_) async => {});

      // Use IOOverrides to intercept File creation
      await IOOverrides.runZoned(() async {
        await controller.messageHandler(message);
      }, createFile: (String path) {
        if (path == expectedImagePath) {
          return mockFile;
        }
        // Throw an error for any unexpected file creation attempts
        throw StateError(
            'Unexpected attempt to create/access file at $path during this test.');
      });

      verify(() => mockHttpClient.get(Uri.parse(imageUrl))).called(1);

      // Verify that writeAsBytes was called on the mockFile
      verify(() => mockFile.writeAsBytes(
            any(that: isA<List<int>>()),
            mode: FileMode.write, // Assuming default mode
            flush: false, // Assuming default flush
          )).called(1);

      verify(() => mockLocalNotifications.show(
            id: any(named: 'id'),
            title: title,
            body: body,
            notificationDetails: any(named: 'notificationDetails', that: predicate<NotificationDetails>((details) {
              final androidDetails = details.android!;
              // Check largeIcon
              expect(androidDetails.largeIcon, isA<FilePathAndroidBitmap>());
              expect((androidDetails.largeIcon as FilePathAndroidBitmap).data,
                  expectedImagePath);
              // Check styleInformation (BigPictureStyle)
              expect(androidDetails.styleInformation,
                  isA<BigPictureStyleInformation>());
              final styleInfo =
                  androidDetails.styleInformation as BigPictureStyleInformation;
              expect(styleInfo.bigPicture, isA<FilePathAndroidBitmap>());
              expect((styleInfo.bigPicture as FilePathAndroidBitmap).data,
                  expectedImagePath);
              expect(styleInfo.contentTitle, '<b>$title</b>');
              expect(styleInfo.htmlFormatContentTitle, isTrue);
              expect(styleInfo.summaryText, body);
              expect(styleInfo.htmlFormatSummaryText, isTrue);
              return true;
            })),
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
            settings: any(named: 'settings'),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).thenAnswer((_) async => true);

      await controller.setupNotificationPlugin();

      verify(() => mockLocalNotifications.initialize(
            settings: any(named: 'settings'),
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
