import 'package:audio_diaries_flutter/services/notification_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart'; // For testing callbacks
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart'; // For Color
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Note: We are not using mockito for AwesomeNotifications or PendoService here.
// Instead, we are mocking the underlying MethodChannels they use.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Using 'plugins.flutter.io/awesome_notifications' as the channel name
  const MethodChannel awesomeNotificationsChannel =
      MethodChannel('plugins.flutter.io/awesome_notifications');
  const MethodChannel pendoChannel = MethodChannel('pendo_flutter_plugin');

  final List<MethodCall> awesomeLog = <MethodCall>[];
  final List<MethodCall> pendoLog = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(awesomeNotificationsChannel,
            (MethodCall methodCall) async {
      awesomeLog.add(methodCall); // Log every call on this channel
      switch (methodCall.method) {
        case 'initialize':
        case 'setListeners':
        case 'createNotification':
        case 'cancelAll':
        case 'cancel':
        case 'cancelSchedule':
        case 'listScheduledNotifications':
          if (methodCall.method == 'listScheduledNotifications') {
            return Future.value([]);
          }
          return Future.value(true);
        case 'isNotificationAllowed':
          return Future.value(true); // Default to permission allowed
        default:
          return Future.value(null);
      }
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pendoChannel, (MethodCall methodCall) async {
      pendoLog.add(methodCall);
      return Future.value(null);
    });

    awesomeLog.clear();
    pendoLog.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(awesomeNotificationsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pendoChannel, null);
  });

  group('NotificationService Tests', () {
    group('init', () {
      test(
          'should call AwesomeNotifications().initialize with correct parameters',
          () async {
        await NotificationService.init();
        expect(awesomeLog.length, 1,
            reason:
                "init should make one call to awesome_notifications channel. Log: $awesomeLog");
        if (awesomeLog.isNotEmpty) {
          final call = awesomeLog.first;
          expect(call.method, 'initialize');
          expect(call.arguments['defaultIcon'], null);
          expect(call.arguments['debug'], true);
          final channels = call.arguments['channels'] as List<dynamic>;
          expect(channels.length, 1);
          final channel = channels.first as Map<dynamic, dynamic>;
          expect(channel['channelKey'], 'audio-diaries');
          expect(channel['channelName'], 'Fabla');
          expect(channel['channelDescription'],
              'Reminders for Daily Diary Entries');
          expect(channel['channelShowBadge'], false);
          expect(channel['defaultColor'], CustomColors.fillWhite.value);
          expect(channel['importance'], NotificationImportance.High.index);
        }
      });
    });

    group('setListeners', () {
      test('should call AwesomeNotifications().setListeners', () async {
        await NotificationService.setListeners();
        expect(awesomeLog.length, 1,
            reason: "setListeners should make one call. Log: $awesomeLog");
        if (awesomeLog.isNotEmpty) {
          final call = awesomeLog.first;
          expect(call.method, 'setListeners');
          expect(call.arguments['onActionReceivedMethod'],
              'onActionReceivedMethod');
          expect(call.arguments['onDismissActionReceivedMethod'],
              'onDismissActionReceivedMethod');
        }
      });
    });

    group('Notification Callbacks', () {
      // TODO: Fix ReceivedAction and ReceivedNotification constructors based on awesome_notifications package version
    });

    group('createNotification', () {
      const id = 123;
      const title = 'Test Title';
      const body = 'Test Body';
      final date = DateTime.now().add(const Duration(hours: 1));
      final payload = {'test_key': 'test_value'};

      test('should call createNotification on channel if permission allowed',
          () async {
        final result = await NotificationService.createNotification(
            id: id, title: title, body: body, date: date, payload: payload);

        expect(result, isTrue,
            reason:
                "createNotification should return true when permission is allowed. Log: $awesomeLog");
        // isNotificationAllowed + createNotification = 2 calls expected if channel is hit
        // However, the main log is cleared by setUp. This test relies on the default isNotificationAllowed mock.
        // The default mock for isNotificationAllowed also logs to awesomeLog.
        // So, one call for isNotificationAllowed and one for createNotification.
        final relevantCalls = awesomeLog
            .where((c) =>
                c.method == 'isNotificationAllowed' ||
                c.method == 'createNotification')
            .toList();
        expect(relevantCalls.length, 2,
            reason:
                "Expected isNotificationAllowed and createNotification calls. Log: $awesomeLog");

        final createCallLog = awesomeLog
            .where((call) => call.method == 'createNotification')
            .toList();
        expect(createCallLog.length, 1,
            reason:
                "createNotification method should be called once. Log: $awesomeLog");

        if (createCallLog.isNotEmpty) {
          final callArgs =
              createCallLog.first.arguments as Map<dynamic, dynamic>;
          final content = callArgs['content'] as Map<dynamic, dynamic>;
          expect(content['id'], id);
          expect(content['channelKey'], 'audio-diaries');
          expect(content['title'], title);
          expect(content['body'], body);
          expect(content['payload'], payload);
          expect(
              content['category'].toString().toLowerCase(),
              NotificationCategory.Reminder.toString()
                  .split('.')
                  .last
                  .toLowerCase());
          expect(content['actionType'].toString().toLowerCase(),
              ActionType.Default.toString().split('.').last.toLowerCase());

          final actionButtons = callArgs['actionButtons'] as List<dynamic>;
          expect(actionButtons.length, 2);
          expect(actionButtons[0]['key'], 'REDIRECT');
          expect(actionButtons[1]['key'], 'DISMISS');
          expect(
              actionButtons[1]['actionType'].toString().toLowerCase(),
              ActionType.DismissAction.toString()
                  .split('.')
                  .last
                  .toLowerCase());

          final schedule = callArgs['schedule'] as Map<dynamic, dynamic>;
          final scheduledDateTime = DateTime.parse(schedule['initialDateTime']);
          expect(scheduledDateTime.year, date.year);
          expect(scheduledDateTime.month, date.month);
          expect(scheduledDateTime.day, date.day);
          expect(scheduledDateTime.hour, date.hour);
          expect(scheduledDateTime.minute, date.minute);
          expect(schedule['preciseAlarm'], true);
        }
      });

      test('should use Random().nextInt for id if id is null', () async {
        await NotificationService.createNotification(
            title: title, body: body, date: date);
        // Expect 2 calls: isNotificationAllowed then createNotification
        expect(
            awesomeLog
                .where((c) =>
                    c.method == 'isNotificationAllowed' ||
                    c.method == 'createNotification')
                .length,
            2,
            reason: "Expected 2 calls for random ID. Log: $awesomeLog");
        final createCallLog = awesomeLog
            .where((call) => call.method == 'createNotification')
            .toList();
        expect(createCallLog.length, 1,
            reason:
                "createNotification for random ID not found. Log: $awesomeLog");
        if (createCallLog.isNotEmpty) {
          final callArgs =
              createCallLog.first.arguments as Map<dynamic, dynamic>;
          final content = callArgs['content'] as Map<dynamic, dynamic>;
          expect(content['id'], isA<int>());
          expect(content['id'], isNot(id));
        }
      });

      test('should return false if notification permission not allowed',
          () async {
        // Temporarily override the handler for this specific test
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(awesomeNotificationsChannel,
                (MethodCall methodCall) async {
          awesomeLog.add(
              methodCall); // Log the call, *including* isNotificationAllowed
          if (methodCall.method == 'isNotificationAllowed') {
            return Future.value(false); // Deny permission
          }
          // For any other unexpected calls on this channel during this test
          return Future.value(null);
        });

        final result = await NotificationService.createNotification(
            title: 't', body: 'b', date: DateTime.now());

        expect(result, isFalse,
            reason:
                "createNotification should return false when permission denied. Log: $awesomeLog");

        final isNotificationAllowedCalls = awesomeLog
            .where((call) => call.method == 'isNotificationAllowed')
            .toList();
        expect(isNotificationAllowedCalls.isNotEmpty, isTrue,
            reason:
                "isNotificationAllowed should have been called by the temporary handler. Log: $awesomeLog");

        final createNotificationCalls = awesomeLog
            .where((call) => call.method == 'createNotification')
            .toList();
        expect(createNotificationCalls.isEmpty, isTrue,
            reason:
                "createNotification should not have been called when permission is denied. Log: $awesomeLog");

        // Restore default handler by re-applying it from setUp logic (done implicitly by next test's setUp)
        // For robustness in case this is the last test or for clarity:
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(awesomeNotificationsChannel,
                (MethodCall methodCall) async {
          awesomeLog.add(methodCall);
          switch (methodCall.method) {
            case 'initialize':
            case 'setListeners':
            case 'createNotification':
            case 'cancelAll':
            case 'cancel':
            case 'cancelSchedule':
            case 'listScheduledNotifications':
              if (methodCall.method == 'listScheduledNotifications')
                return Future.value([]);
              return Future.value(true);
            case 'isNotificationAllowed':
              return Future.value(true);
            default:
              return Future.value(null);
          }
        });
      });
    });

    group('cancelAllNotifications', () {
      test('should call cancelAll on channel', () async {
        await NotificationService.cancelAllNotifications();
        expect(awesomeLog.length, 1,
            reason: "cancelAll should make one call. Log: $awesomeLog");
        if (awesomeLog.isNotEmpty) {
          expect(awesomeLog.first.method, 'cancelAll');
          expect(awesomeLog.first.arguments, null);
        }
      });
    });

    group('cancelNotification', () {
      test('should call cancel on channel with id', () async {
        const id = 456;
        await NotificationService.cancelNotification(id);
        expect(awesomeLog.length, 1,
            reason:
                "cancelNotification should make one call. Log: $awesomeLog");
        if (awesomeLog.isNotEmpty) {
          expect(awesomeLog.first.method, 'cancel');
          expect(awesomeLog.first.arguments, id);
        }
      });
    });

    group('rescheduleNotification', () {
      test('should call cancelSchedule and then createNotification', () async {
        const originalId = 789;
        const title = 'Rescheduled Title';
        const body = 'Rescheduled Body';
        final date = DateTime.now().add(const Duration(days: 1));
        final payload = {'rescheduled_key': 'true_value'};

        // This test relies on the default mock handler (from global setUp)
        // which allows isNotificationAllowed and createNotification, and logs calls.
        // cancelSchedule is also mocked to succeed and log by the default handler.

        final result = await NotificationService.rescheduleNotification(
            id: originalId,
            title: title,
            body: body,
            date: date,
            payload: payload);

        expect(result, isTrue,
            reason:
                "rescheduleNotification should return true. Log: $awesomeLog");

        // Expected calls: cancelSchedule, isNotificationAllowed, createNotification
        final cancelCall = awesomeLog.firstWhere(
            (c) => c.method == 'cancelSchedule',
            orElse: () => const MethodCall('notFoundLogIsEmpty'));
        expect(cancelCall.method, 'cancelSchedule',
            reason: "cancelSchedule not found. Log: $awesomeLog");
        expect(cancelCall.arguments, originalId);

        final isAllowedCall = awesomeLog.firstWhere(
            (c) => c.method == 'isNotificationAllowed',
            orElse: () => const MethodCall('notFoundLogIsEmpty'));
        expect(isAllowedCall.method, 'isNotificationAllowed',
            reason: "isNotificationAllowed not found. Log: $awesomeLog");

        final createCall = awesomeLog.firstWhere(
            (c) => c.method == 'createNotification',
            orElse: () => const MethodCall('notFoundLogIsEmpty'));
        expect(createCall.method, 'createNotification',
            reason:
                "createNotification in reschedule not found. Log: $awesomeLog");
        if (createCall.method == 'createNotification') {
          final createArgs = createCall.arguments as Map<dynamic, dynamic>;
          final content = createArgs['content'] as Map<dynamic, dynamic>;
          expect(content['title'], title);
          expect(content['body'], body);
          expect(content['payload'], payload);
          expect(content['id'], isA<int>());
          expect(content['id'], isNot(originalId));
        }
      });
    });

    group('getScheduledNotifications', () {
      test(
          'should call listScheduledNotifications on channel and return mapped results',
          () async {
        final mockNotificationData = [
          {
            'content': {
              'id': 101,
              'channelKey': 'scheduled_key1',
              'title': 'Scheduled Title 1',
              'body': 'Scheduled Body 1',
              'payload': {'s_key': 's_val1'},
              'summary': 'Test Summary',
              'wakeUpScreen': false,
              'fullScreenIntent': false,
              'criticalAlert': false,
              'category': NotificationCategory.Reminder.name,
              'notificationLayout': NotificationLayout.Default.name,
              'locked': false,
              'showWhen': true,
              'displayOnBackground': true,
              'displayOnForeground': true,
              'hideLargeIconOnExpand': false,
              'progress': null,
              'ticker': 'Test Ticker',
              'largeIcon': null,
              'bigPicture': null,
              'autoDismissible': true,
              'color': Colors.blue.value,
              'backgroundColor': Colors.white.value,
              'roundedLargeIcon': false,
              'roundedBigPicture': false,
            },
            'schedule': {
              'timeZone':
                  'UTC', // Using 'UTC' as a placeholder for AwesomeNotifications.localTimezoneIdentifier
              'initialDateTime': DateTime.now().toIso8601String(),
              'crontabSchedule': null,
              'allowWhileIdle': false, 'preciseAlarm': true, 'repeats': false,
              'createdDate': DateTime.now().toIso8601String(),
              'createdLifeCycle': NotificationLifeCycle.AppKilled.name,
            }
          }
        ];
        final defaultAwesomeHandler = (MethodCall methodCall) async {
          awesomeLog.add(methodCall);
          switch (methodCall.method) {
            case 'initialize':
            case 'setListeners':
            case 'createNotification':
            case 'cancelAll':
            case 'cancel':
            case 'cancelSchedule':
            case 'listScheduledNotifications':
              if (methodCall.method == 'listScheduledNotifications') {
                return Future.value([]); // Default from setUp
              }
              return Future.value(true);
            case 'isNotificationAllowed':
              return Future.value(true);
            default:
              return Future.value(null);
          }
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(awesomeNotificationsChannel,
                (MethodCall methodCall) async {
          awesomeLog.add(methodCall);
          if (methodCall.method == 'listScheduledNotifications') {
            return Future.value(mockNotificationData);
          }
          return Future.value(
              null); // Default for other calls during this specific test
        });

        final notifications =
            await NotificationService.getScheduledNotifications();

        expect(
            awesomeLog
                .any((call) => call.method == 'listScheduledNotifications'),
            isTrue,
            reason:
                "listScheduledNotifications should have been called. Log: $awesomeLog");
        expect(notifications, isA<List<NotificationModel>>());
        expect(notifications.length, 1);
        if (notifications.isNotEmpty) {
          final firstNotification = notifications.first;
          expect(firstNotification.content?.id, 101);
          expect(firstNotification.content?.title, 'Scheduled Title 1');
          expect(firstNotification.content?.payload, {'s_key': 's_val1'});
          expect(firstNotification.schedule?.timeZone,
              'UTC'); // Check against the placeholder
        }

        // Restore default handler
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
                awesomeNotificationsChannel, defaultAwesomeHandler);
      });
    });
  });
}
