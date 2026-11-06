import 'dart:convert';

import 'package:audio_diaries_flutter/core/usecases/notification_manager.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/services/notification_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dummy_data.dart';

class MockDiaryRepository extends Mock implements DiaryRepository {}

class MockAwesomeNotifications extends Mock implements AwesomeNotifications {}

class RecordingPendoPlugin implements IPendoPlugin {
  final List<MethodCall> calls = [];

  @override
  Future<void> setup(String pendoKey) async {}

  @override
  Future<void> startSession(
    String visitorId,
    String accountId,
    Map<String, dynamic>? visitorData,
    Map<String, dynamic>? accountData,
  ) async {}

  @override
  Future<void> endSession() async {}

  @override
  Future<void> track(
    String eventName,
    Map<String, dynamic>? properties,
  ) async {
    calls.add(MethodCall(eventName, properties));
  }
}

class ScheduledNotification {
  final NotificationContent content;
  final NotificationCalendar schedule;

  ScheduledNotification(this.content, this.schedule);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDiaryRepository diaryRepository;
  late MockAwesomeNotifications awesomeNotifications;
  late RecordingPendoPlugin pendoPlugin;
  late List<ScheduledNotification> scheduledNotifications;

  setUpAll(() {
    registerFallbackValue(
      NotificationContent(id: 0, channelKey: 'audio-diaries'),
    );
    registerFallbackValue(
      NotificationCalendar.fromDate(date: DateTime(2026)),
    );
    registerFallbackValue(<NotificationActionButton>[]);
  });

  setUp(() {
    diaryRepository = MockDiaryRepository();
    awesomeNotifications = MockAwesomeNotifications();
    pendoPlugin = RecordingPendoPlugin();
    scheduledNotifications = [];

    NotificationService.setAwesomeNotificationsForTesting(
      awesomeNotifications,
    );
    PendoService.setPluginForTesting(pendoPlugin);

    when(() => awesomeNotifications.cancelAll()).thenAnswer((_) async {});
    when(() => awesomeNotifications.isNotificationAllowed())
        .thenAnswer((_) async => true);
    when(
      () => awesomeNotifications.createNotification(
        content: any(named: 'content'),
        actionButtons: any(named: 'actionButtons'),
        schedule: any(named: 'schedule'),
      ),
    ).thenAnswer((invocation) async {
      scheduledNotifications.add(
        ScheduledNotification(
          invocation.namedArguments[#content] as NotificationContent,
          invocation.namedArguments[#schedule] as NotificationCalendar,
        ),
      );
      return true;
    });
  });

  tearDown(() {
    NotificationService.resetAwesomeNotifications();
    NotificationService.channelDisabled.value = false;
    PendoService.resetPlugin();
  });

  group('scheduleDiaryNotifications', () {
    test(
      'schedules selected, late-night, and day-before reminders and persists IDs',
      () async {
        final firstStart = DateTime(2026, 10, 20);
        final secondStart = DateTime(2026, 10, 21);
        final diaries = [
          createTestDiaryModel(id: 1, start: firstStart),
          createTestDiaryModel(id: 2, start: secondStart),
        ];
        when(() => diaryRepository.getAllDiaries()).thenReturn(diaries);
        SharedPreferences.setMockInitialValues({
          'reminder_times': [
            DateTime(0, 1, 1, 8).toString(),
            DateTime(0, 1, 1, 20).toString(),
          ],
        });

        await NotificationManager(diaryRepository: diaryRepository)
            .scheduleDiaryNotifications(page: 'settings');

        expect(scheduledNotifications, hasLength(7));
        expect(
          scheduledNotifications.map(_scheduledDate),
          containsAll(<DateTime>[
            DateTime(2026, 10, 20, 8),
            DateTime(2026, 10, 20, 20),
            DateTime(2026, 10, 20, 23),
            DateTime(2026, 10, 21, 8),
            DateTime(2026, 10, 21, 20),
            DateTime(2026, 10, 21, 23),
            DateTime(2026, 10, 19, 8),
          ]),
        );
        expect(
          _notificationAt(scheduledNotifications, DateTime(2026, 10, 20, 8))
              .content
              .title,
          'Get Started on Your Diary Journey!',
        );
        expect(
          _notificationAt(scheduledNotifications, DateTime(2026, 10, 20, 8))
              .content
              .body,
          contains("It's time to start your diary"),
        );
        expect(
          _notificationAt(scheduledNotifications, DateTime(2026, 10, 21, 8))
              .content
              .title,
          'Keep Going on Your Diary Journey!',
        );
        expect(
          _notificationAt(scheduledNotifications, DateTime(2026, 10, 20, 23))
              .content
              .title,
          "Let's Get Started on Your Diary!",
        );
        expect(
          _notificationAt(scheduledNotifications, DateTime(2026, 10, 20, 23))
              .content
              .body,
          contains("it's not too late to begin"),
        );
        expect(
          _notificationAt(scheduledNotifications, DateTime(2026, 10, 19, 8))
              .content
              .title,
          'Get Ready - Your Study Starts Tomorrow!',
        );

        final preferences = await SharedPreferences.getInstance();
        final stored = json.decode(
          preferences.getString('diary_notifications')!,
        ) as Map<String, dynamic>;
        expect(stored['1'], hasLength(3));
        expect(stored['2'], hasLength(3));

        expect(pendoPlugin.calls, hasLength(2));
        expect(pendoPlugin.calls[0].method, 'ScheduleReminder');
        expect(
            pendoPlugin.calls[0].arguments, containsPair('page', 'settings'));
        expect(
          pendoPlugin.calls[0].arguments,
          containsPair('notification_type', 'reminder'),
        );
        expect(
          pendoPlugin.calls[1].arguments,
          containsPair('notification_type', 'late_night'),
        );
        verify(() => awesomeNotifications.cancelAll()).called(1);
      },
    );

    test('uses 9 PM and 5 PM fallbacks when no reminder times exist', () async {
      final start = DateTime(2026, 10, 20);
      when(() => diaryRepository.getAllDiaries())
          .thenReturn([createTestDiaryModel(id: 7, start: start)]);
      SharedPreferences.setMockInitialValues({});

      await NotificationManager(diaryRepository: diaryRepository)
          .scheduleDiaryNotifications();

      expect(scheduledNotifications, hasLength(2));
      expect(
        scheduledNotifications.map(_scheduledDate),
        containsAll(<DateTime>[
          DateTime(2026, 10, 20, 21),
          DateTime(2026, 10, 19, 17),
        ]),
      );

      final preferences = await SharedPreferences.getInstance();
      final stored = json.decode(
        preferences.getString('diary_notifications')!,
      ) as Map<String, dynamic>;
      expect(stored['7'], hasLength(1));
      expect(pendoPlugin.calls, hasLength(1));
      expect(
        pendoPlugin.calls.single.arguments,
        containsPair('reminder_times', ['21:00']),
      );
    });

    test('returns safely without scheduling when there are no diaries',
        () async {
      when(() => diaryRepository.getAllDiaries()).thenReturn([]);
      SharedPreferences.setMockInitialValues({
        'reminder_times': [DateTime(0, 1, 1, 8).toString()],
      });

      await NotificationManager(diaryRepository: diaryRepository)
          .scheduleDiaryNotifications();

      expect(scheduledNotifications, isEmpty);
      expect(pendoPlugin.calls, isEmpty);
      verify(() => awesomeNotifications.cancelAll()).called(1);
      verifyNever(
        () => awesomeNotifications.createNotification(
          content: any(named: 'content'),
          actionButtons: any(named: 'actionButtons'),
          schedule: any(named: 'schedule'),
        ),
      );
    });
  });
}

DateTime _scheduledDate(ScheduledNotification notification) {
  final schedule = notification.schedule;
  return DateTime(
    schedule.year!,
    schedule.month!,
    schedule.day!,
    schedule.hour!,
    schedule.minute!,
  );
}

ScheduledNotification _notificationAt(
  List<ScheduledNotification> notifications,
  DateTime date,
) {
  return notifications.singleWhere(
    (notification) => _scheduledDate(notification) == date,
  );
}
