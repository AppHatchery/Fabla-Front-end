import 'dart:convert';
import 'dart:math';

import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/services/notification_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';

class DiaryNotificationManager {
  final DiaryRepository diaryRepository;
  final PreferenceService preferenceService;
  final NotificationService notificationService;

  List<DateTime> dateArray = [];
  List<Map<String, dynamic>> notifArray = [];

  DiaryNotificationManager({
    required this.diaryRepository,
    required this.preferenceService,
    required this.notificationService,
  });

  Future<void> initialize() async {
    await _initializeDateArray();
    await _loadNotifArray();
    await createInitialNotifications();
  }

  Future<void> _initializeDateArray() async {
    final String? lastInitDate = await preferenceService.getStringPreference(key: 'last_init_date');
    final DateTime startDate = lastInitDate != null ? DateTime.parse(lastInitDate) : DateTime.now();

    dateArray = List.generate(14, (index) => startDate.add(Duration(days: index)));
    
    await preferenceService.setStringPreference(
      key: 'last_init_date',
      value: startDate.toIso8601String(),
    );
  }

  Future<void> _loadNotifArray() async {
    final String? savedNotifArray = await preferenceService.getStringPreference(key: 'notif_array');
    if (savedNotifArray != null) {
      notifArray = List<Map<String, dynamic>>.from(json.decode(savedNotifArray));
    }
  }

  Future<void> createInitialNotifications() async {
    if (notifArray.isEmpty) {
      await _createNotificationsForDays(5);
    }
  }

  Future<void> _createNotificationsForDays(int days) async {
    final emaDiaries = diaryRepository.getEMADiaries();
    final dailyDiary = diaryRepository.getDiariesDaily();
    final surveyDiary = diaryRepository.getSurveyDiaries();

    for (int i = 0; i < days; i++) {
      if (i >= dateArray.length) break;

      final date = dateArray[i];
      final dayNotifications = await _createNotificationsForDate(date, emaDiaries, dailyDiary, surveyDiary);
      notifArray.add({
        'date': date.toIso8601String(),
        'notifications': dayNotifications,
      });
    }

    await _saveNotifArray();
  }

  Future<List<Map<String, dynamic>>> _createNotificationsForDate(
    DateTime date,
    List<DiaryModel> emaDiaries,
    List<DiaryModel> dailyDiary,
    List<DiaryModel> surveyDiaries,

  ) async {
    List<Map<String, dynamic>> dayNotifications = [];

    // Create EMA notifications
    for (final diary in emaDiaries) {
      final notifications = await _createEMANotifications(diary, date);
      dayNotifications.addAll(notifications);
    }

    // // Create daily diary notification
    // final dailyNotification = await _createDailyDiaryNotification(dailyDiary, date);
    // dayNotifications.add(dailyNotification);

    // // Create survey notifications
    // for (final diary in surveyDiaries) {
    //   final notification = await _createSurveyNotification(diary, date);
    //   dayNotifications.add(notification);
    // }

    return dayNotifications;
  }

  Future<List<Map<String, dynamic>>> _createEMANotifications(DiaryModel diary, DateTime date) async {
    final startTime = DateTime(date.year, date.month, date.day, diary.start.hour, diary.start.minute);
    final endTime = DateTime(date.year, date.month, date.day, diary.end.hour, diary.end.minute);

    final startNotificationTime = startTime;
    final midNotificationTime = startTime.add(const Duration(hours: 1));
    final endNotificationTime = endTime.subtract(const Duration(minutes: 15));

    List<Map<String, dynamic>> notifications = [];

    for (final time in [startNotificationTime, midNotificationTime, endNotificationTime]) {
      String title;
      String body;

      if (time == startNotificationTime) {
        title = "It's Time to Do Your EMA";
        body = "Hey there, your EMA period has begun, you have two hours to complete this EMA before it won't be available";
      } else if (time == midNotificationTime) {
        title = "Your EMA is Pending";
        body = "Only 1 hour left to complete the EMA, it will take you 5 minutes, you don't want to miss this";
      } else {
        title = "Your EMA is Due Soon";
        body = "Hey there, you have only 15 mins to complete this EMA, try to grab a second from what you are doing and try to complete, shouldn't take you more than 5 minutes";
      }

      final notificationID = Random().nextInt(100000);
      await NotificationService.createNotification(
        id: notificationID,
        title: title,
        body: body,
        date: time,
      );

      notifications.add({
        'id': notificationID,
        'title': title,
        'body': body,
        'time': time.toIso8601String(),
      });
    }

    return notifications;
  }

  Future<Map<String, dynamic>> _createDailyDiaryNotification(DiaryModel diary, DateTime date) async {
    final notificationTime = DateTime(date.year, date.month, date.day, diary.start.hour, diary.start.minute);
    final notificationID = Random().nextInt(100000);

    await NotificationService.createNotification(
      id: notificationID,
      title: "Daily Diary Reminder",
      body: "It's time to complete your daily diary entry.",
      date: notificationTime,
    );

    return {
      'id': notificationID,
      'title': "Daily Diary Reminder",
      'body': "It's time to complete your daily diary entry.",
      'time': notificationTime.toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _createSurveyNotification(DiaryModel diary, DateTime date) async {
    final notificationTime = DateTime(date.year, date.month, date.day, diary.start.hour, diary.start.minute);
    final notificationID = Random().nextInt(100000);

    await NotificationService.createNotification(
      id: notificationID,
      title: "Survey Reminder",
      body: "Don't forget to complete your survey today.",
      date: notificationTime,
    );

    return {
      'id': notificationID,
      'title': "Survey Reminder",
      'body': "Don't forget to complete your survey today.",
      'time': notificationTime.toIso8601String(),
    };
  }

  Future<void> _saveNotifArray() async {
    final encoded = json.encode(notifArray);
    await preferenceService.setStringPreference(key: 'notif_array', value: encoded);
  }

  Future<void> checkAndCreateNotifications() async {
    final now = DateTime.now();
    notifArray.removeWhere((item) => DateTime.parse(item['date']).isBefore(now));

    final daysWithNotifications = notifArray.length;
    if (daysWithNotifications < 5) {
      final daysToCreate = 5 - daysWithNotifications;
      await _createNotificationsForDays(daysToCreate);
    }
  }
}
