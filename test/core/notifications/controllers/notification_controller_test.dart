import 'package:audio_diaries_flutter/core/notifications/controllers/notifications_controller.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../firebase_mock.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockAwesomeNotifications extends Mock implements AwesomeNotifications {}

void main() {
  late NotificationsController controller;
  late MockFirebaseMessaging mockFirebaseMessaging;
  late MockAwesomeNotifications mockNotifications;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    setupFirebaseMocks();
    registerFallbackValue(NotificationContent(id: 0, channelKey: 'x'));
  });

  setUp(() {
    mockFirebaseMessaging = MockFirebaseMessaging();
    mockNotifications = MockAwesomeNotifications();
    when(() => mockNotifications.createNotification(
        content: any(named: 'content'))).thenAnswer((_) async => true);
    controller = NotificationsController(
      messaging: mockFirebaseMessaging,
      notifications: mockNotifications,
    );
  });

  NotificationContent shown() => verify(() => mockNotifications
          .createNotification(content: captureAny(named: 'content')))
      .captured
      .single as NotificationContent;

  group('NotificationsController Tests', () {
    test('initialize reads the initial message', () async {
      when(() => mockFirebaseMessaging.getInitialMessage())
          .thenAnswer((_) async => null);

      await controller.initialize();

      verify(() => mockFirebaseMessaging.getInitialMessage()).called(1);
    });

    test('messageHandler shows an Android message on the push channel',
        () async {
      await controller.messageHandler(const RemoteMessage(
        messageId: 'm1',
        notification: RemoteNotification(
            title: 'Hello', body: 'World', android: AndroidNotification()),
      ));

      final content = shown();
      expect(content.channelKey, pushChannelKey);
      expect(content.title, 'Hello');
      expect(content.body, 'World');
      expect(content.notificationLayout, NotificationLayout.Default);
      expect(content.id, greaterThanOrEqualTo(0));
    });

    test('messageHandler uses the big-picture layout for an image', () async {
      await controller.messageHandler(const RemoteMessage(
        notification: RemoteNotification(
            title: 'Hello',
            body: 'World',
            android:
                AndroidNotification(imageUrl: 'https://example.com/a.png')),
      ));

      final content = shown();
      expect(content.notificationLayout, NotificationLayout.BigPicture);
      expect(content.bigPicture, 'https://example.com/a.png');
    });

    test('messageHandler ignores data-only and non-Android messages', () async {
      await controller.messageHandler(const RemoteMessage(data: {'a': 'b'}));
      await controller.messageHandler(const RemoteMessage(
          notification: RemoteNotification(title: 't', body: 'b')));

      verifyNever(() =>
          mockNotifications.createNotification(content: any(named: 'content')));
    });

    test('messageHandler does not throw when showing fails', () async {
      when(() => mockNotifications.createNotification(
          content: any(named: 'content'))).thenThrow(Exception('boom'));

      await controller.messageHandler(const RemoteMessage(
        notification: RemoteNotification(
            title: 't', body: 'b', android: AndroidNotification()),
      ));
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
  });
}
