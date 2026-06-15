import 'package:audio_diaries_flutter/services/notification_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Coverage:
//  init()                       - initialize is called
//  setListeners()               - listeners are set
//  openChannelSettings()        - opens the OS channel config page
//  createNotification()         - allowed / denied / PlatformException / non-Platform error
//                                 + channelDisabled ValueNotifier transitions
//  cancelAllNotifications()     - cancelAll is called
//  cancelNotification()         - cancel is called with the correct id
//  rescheduleNotification()     - cancelSchedule + createNotification ordering
//                                 + channelDisabled propagation from createNotification
//  getScheduledNotifications()  - list is returned verbatim

@GenerateMocks([AwesomeNotifications])
import 'notification_service_test.mocks.dart';

void main() {
  late MockAwesomeNotifications mockAwesome;

  setUp(() {
    mockAwesome = MockAwesomeNotifications();
    NotificationService.setAwesomeNotificationsForTesting(mockAwesome);
    // ValueNotifier is static — reset between tests so leakage doesn't
    // mask regressions in the disable/enable transitions.
    NotificationService.channelDisabled.value = false;
  });

  tearDown(() {
    NotificationService.resetAwesomeNotifications();
    NotificationService.channelDisabled.value = false;
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

    test(
        'openChannelSettings opens the system config page for the audio-diaries channel',
        () async {
      // Arrange
      when(mockAwesome.showNotificationConfigPage(
        channelKey: anyNamed('channelKey'),
      )).thenAnswer((_) async {});

      // Act
      await NotificationService.openChannelSettings();

      // Assert
      verify(mockAwesome.showNotificationConfigPage(channelKey: 'audio-diaries'))
          .called(1);
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
        date: DateTime.now().add(const Duration(hours: 1)),
      );

      // Assert
      expect(result, true);
      expect(NotificationService.channelDisabled.value, isFalse);
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
        date: DateTime.now().add(const Duration(hours: 1)),
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

    test(
        'createNotification flips channelDisabled to true when permission denied',
        () async {
      // Arrange
      when(mockAwesome.isNotificationAllowed()).thenAnswer((_) async => false);
      final emissions = <bool>[];
      void listener() => emissions.add(NotificationService.channelDisabled.value);
      NotificationService.channelDisabled.addListener(listener);

      // Act
      final result = await NotificationService.createNotification(
        title: 'Test',
        body: 'Body',
        date: DateTime.now().add(const Duration(hours: 1)),
      );

      // Assert
      expect(result, isFalse);
      expect(NotificationService.channelDisabled.value, isTrue);
      // Single transition false -> true.
      expect(emissions, [true]);

      // Cleanup
      NotificationService.channelDisabled.removeListener(listener);
    });

    test(
        'createNotification resets channelDisabled to false on success when previously true',
        () async {
      // Arrange — simulate a prior failure leaving the flag set.
      NotificationService.channelDisabled.value = true;
      when(mockAwesome.isNotificationAllowed()).thenAnswer((_) async => true);
      when(mockAwesome.createNotification(
        content: anyNamed('content'),
        actionButtons: anyNamed('actionButtons'),
        schedule: anyNamed('schedule'),
      )).thenAnswer((_) async => true);

      final emissions = <bool>[];
      void listener() => emissions.add(NotificationService.channelDisabled.value);
      NotificationService.channelDisabled.addListener(listener);

      // Act
      final result = await NotificationService.createNotification(
        title: 'Test',
        body: 'Body',
        date: DateTime.now().add(const Duration(hours: 1)),
      );

      // Assert
      expect(result, isTrue);
      expect(NotificationService.channelDisabled.value, isFalse);
      // Single transition true -> false.
      expect(emissions, [false]);

      // Cleanup
      NotificationService.channelDisabled.removeListener(listener);
    });

    test(
        'createNotification does not emit on success when channelDisabled was already false',
        () async {
      // Arrange
      when(mockAwesome.isNotificationAllowed()).thenAnswer((_) async => true);
      when(mockAwesome.createNotification(
        content: anyNamed('content'),
        actionButtons: anyNamed('actionButtons'),
        schedule: anyNamed('schedule'),
      )).thenAnswer((_) async => true);

      final emissions = <bool>[];
      void listener() => emissions.add(NotificationService.channelDisabled.value);
      NotificationService.channelDisabled.addListener(listener);

      // Act
      await NotificationService.createNotification(
        title: 'Test',
        body: 'Body',
        date: DateTime.now().add(const Duration(hours: 1)),
      );

      // Assert — no redundant rebuilds for downstream ValueListenableBuilders.
      expect(emissions, isEmpty);
      expect(NotificationService.channelDisabled.value, isFalse);

      // Cleanup
      NotificationService.channelDisabled.removeListener(listener);
    });

    test(
        'createNotification catches PlatformException, returns false, and sets channelDisabled',
        () async {
      // Arrange — the exact crash shape from Crashlytics issue
      // aea3265a1294cd0e06ce5cf23f1c24ef.
      when(mockAwesome.isNotificationAllowed()).thenAnswer((_) async => true);
      when(mockAwesome.createNotification(
        content: anyNamed('content'),
        actionButtons: anyNamed('actionButtons'),
        schedule: anyNamed('schedule'),
      )).thenThrow(PlatformException(
        code: 'INVALID_ARGUMENTS',
        message: "Channel 'audio-diaries' do not exist or is disabled",
        details: 'insufficientPermissions.channel.audio-diaries',
      ));

      // Act
      final result = await NotificationService.createNotification(
        title: 'Test',
        body: 'Body',
        date: DateTime.now().add(const Duration(hours: 1)),
      );

      // Assert
      expect(result, isFalse);
      expect(NotificationService.channelDisabled.value, isTrue);
    });

    test(
        'createNotification rethrows non-PlatformException errors instead of swallowing',
        () async {
      // Arrange — a programmer error (unexpected exception type) should
      // surface, not be silently swallowed as "channel disabled."
      when(mockAwesome.isNotificationAllowed()).thenAnswer((_) async => true);
      when(mockAwesome.createNotification(
        content: anyNamed('content'),
        actionButtons: anyNamed('actionButtons'),
        schedule: anyNamed('schedule'),
      )).thenThrow(StateError('unexpected'));

      // Act + Assert
      await expectLater(
        NotificationService.createNotification(
          title: 'Test',
          body: 'Body',
          date: DateTime.now().add(const Duration(hours: 1)),
        ),
        throwsA(isA<StateError>()),
      );
      // Flag must not be tainted by an unrelated error.
      expect(NotificationService.channelDisabled.value, isFalse);
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
        date: DateTime.now().add(const Duration(days: 1)),
      );

      // Assert
      expect(result, true);
      // cancelSchedule must precede createNotification — verify order.
      verifyInOrder([
        mockAwesome.cancelSchedule(id),
        mockAwesome.isNotificationAllowed(),
        mockAwesome.createNotification(
          content: anyNamed('content'),
          actionButtons: anyNamed('actionButtons'),
          schedule: anyNamed('schedule'),
        ),
      ]);
    });

    test(
        'rescheduleNotification propagates channelDisabled state when permission denied',
        () async {
      // Arrange
      const id = 789;
      when(mockAwesome.cancelSchedule(id)).thenAnswer((_) async => true);
      when(mockAwesome.isNotificationAllowed()).thenAnswer((_) async => false);

      // Act
      final result = await NotificationService.rescheduleNotification(
        id: id,
        title: 'New Title',
        body: 'New Body',
        date: DateTime.now().add(const Duration(days: 1)),
      );

      // Assert
      expect(result, isFalse);
      expect(NotificationService.channelDisabled.value, isTrue);
      // Existing schedule should still have been cleared even though the
      // reschedule failed downstream.
      verify(mockAwesome.cancelSchedule(id)).called(1);
      verifyNever(mockAwesome.createNotification(
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

    test('getScheduledNotifications returns empty list when none scheduled',
        () async {
      // Arrange
      when(mockAwesome.listScheduledNotifications())
          .thenAnswer((_) async => <NotificationModel>[]);

      // Act
      final result = await NotificationService.getScheduledNotifications();

      // Assert
      expect(result, isEmpty);
      verify(mockAwesome.listScheduledNotifications());
    });
  });
}
