import 'package:audio_diaries_flutter/services/notification_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// The test covers all the main functionality of NotificationService:
//  init() - Verifies initialization is called
//  setListeners() - Verifies listeners are set
//  createNotification() - Tests both allowed and denied permission scenarios
//  cancelAllNotifications() - Verifies cancelAll is called
//  cancelNotification() - Verifies cancel is called with correct ID
//  rescheduleNotification() - Verifies the sequence of cancelSchedule and createNotification
//  getScheduledNotifications() - Verifies the list is returned properly

// Generate mocks for AwesomeNotifications
@GenerateMocks([AwesomeNotifications])
import 'notification_service_test.mocks.dart';

void main() {
  late MockAwesomeNotifications mockAwesome;

  setUp(() {
    mockAwesome = MockAwesomeNotifications();
    NotificationService.setAwesomeNotificationsForTesting(mockAwesome);
  });

  tearDown(() {
    NotificationService.resetAwesomeNotifications();
    clearInteractions(mockAwesome);
  });

  group('NotificationService Tests', () {
    test('init should initialize notifications', () async {
      // Arrange
      when(mockAwesome.initialize(any, any, debug: true))
          .thenAnswer((_) async => true);

      // Act
      await NotificationService.init();

      // Assert
      verify(mockAwesome.initialize(any, any, debug: true));
    });

    test('setListeners should set notification listeners', () async {
      // Arrange
      when(mockAwesome.setListeners(
        onActionReceivedMethod: anyNamed('onActionReceivedMethod'),
        onDismissActionReceivedMethod:
            anyNamed('onDismissActionReceivedMethod'),
      )).thenAnswer((_) async => true);

      // Act
      await NotificationService.setListeners();

      // Assert
      verify(mockAwesome.setListeners(
        onActionReceivedMethod: anyNamed('onActionReceivedMethod'),
        onDismissActionReceivedMethod:
            anyNamed('onDismissActionReceivedMethod'),
      ));
    });

    test('createNotification returns true when allowed', () async {
      // Arrange
      when(mockAwesome.isNotificationAllowed()).thenAnswer((_) async => true);
      when(mockAwesome.createNotification(
        content: anyNamed('content'),
        actionButtons: anyNamed('actionButtons'),
        schedule: anyNamed('schedule'),
      )).thenAnswer((_) async => true);

      // Act
      final result = await NotificationService.createNotification(
        title: 'Test',
        body: 'Body',
        date: DateTime.now().add(Duration(hours: 1)),
      );

      // Assert
      expect(result, true);
      verify(mockAwesome.isNotificationAllowed());
      verify(mockAwesome.createNotification(
        content: anyNamed('content'),
        actionButtons: anyNamed('actionButtons'),
        schedule: anyNamed('schedule'),
      ));
    });

    test('createNotification returns false when not allowed', () async {
      // Arrange
      when(mockAwesome.isNotificationAllowed()).thenAnswer((_) async => false);

      // Act
      final result = await NotificationService.createNotification(
        title: 'Test',
        body: 'Body',
        date: DateTime.now().add(Duration(hours: 1)),
      );

      // Assert
      expect(result, false);
      verify(mockAwesome.isNotificationAllowed());
      verifyNever(mockAwesome.createNotification(
        content: anyNamed('content'),
        actionButtons: anyNamed('actionButtons'),
        schedule: anyNamed('schedule'),
      ));
    });

    test('cancelAllNotifications calls cancelAll', () async {
      // Arrange
      when(mockAwesome.cancelAll()).thenAnswer((_) async => true);

      // Act
      await NotificationService.cancelAllNotifications();

      // Assert
      verify(mockAwesome.cancelAll());
    });

    test('cancelNotification calls cancel with id', () async {
      // Arrange
      const id = 123;
      when(mockAwesome.cancel(id)).thenAnswer((_) async => true);

      // Act
      await NotificationService.cancelNotification(id);

      // Assert
      verify(mockAwesome.cancel(id));
    });

    test('rescheduleNotification calls cancelSchedule and createNotification',
        () async {
      // Arrange
      const id = 456;
      when(mockAwesome.cancelSchedule(id)).thenAnswer((_) async => true);
      when(mockAwesome.isNotificationAllowed()).thenAnswer((_) async => true);
      when(mockAwesome.createNotification(
        content: anyNamed('content'),
        actionButtons: anyNamed('actionButtons'),
        schedule: anyNamed('schedule'),
      )).thenAnswer((_) async => true);

      // Act
      final result = await NotificationService.rescheduleNotification(
        id: id,
        title: 'New Title',
        body: 'New Body',
        date: DateTime.now().add(Duration(days: 1)),
      );

      // Assert
      expect(result, true);
      verify(mockAwesome.cancelSchedule(id));
      verify(mockAwesome.isNotificationAllowed());
      verify(mockAwesome.createNotification(
        content: anyNamed('content'),
        actionButtons: anyNamed('actionButtons'),
        schedule: anyNamed('schedule'),
      ));
    });

    test('getScheduledNotifications returns list from awesome notifications',
        () async {
      // Arrange
      final mockNotifications = <NotificationModel>[
        NotificationModel(
          content: NotificationContent(
            id: 1,
            channelKey: 'test',
            title: 'Test Title',
            body: 'Test Body',
          ),
        ),
      ];
      when(mockAwesome.listScheduledNotifications())
          .thenAnswer((_) async => mockNotifications);

      // Act
      final result = await NotificationService.getScheduledNotifications();

      // Assert
      expect(result, mockNotifications);
      verify(mockAwesome.listScheduledNotifications());
    });
  });
}
