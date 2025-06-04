import 'package:flutter_test/flutter_test.dart';
import 'package:audio_diaries_flutter/core/utils/extensions.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/notification.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/options.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';

void main() {
  group('PromptModelComparison Tests', () {
    test('isEffectivelyEqual should compare prompts correctly', () {
      final prompt1 = PromptModel(
        questionNumber: 1,
        question: 'Test question',
        required: true,
        responseType: ResponseType.audio,
        multipleAnswer: false,
      );

      final prompt2 = PromptModel(
        questionNumber: 1,
        question: 'Test question',
        required: true,
        responseType: ResponseType.audio,
        multipleAnswer: false,
      );

      final prompt3 = PromptModel(
        questionNumber: 1,
        question: 'Different question',
        required: true,
        responseType: ResponseType.audio,
        multipleAnswer: false,
      );

      expect(prompt1.isEffectivelyEqual(prompt2), isTrue);
      expect(prompt1.isEffectivelyEqual(prompt3), isFalse);
    });

    test('isEffectivelyEqual should handle options correctly', () {
      final prompt1 = PromptModel(
        questionNumber: 1,
        question: 'Test question',
        required: true,
        responseType: ResponseType.radio,
        option: Options(type: OptionsType.radio),
        multipleAnswer: false,
      );

      final prompt2 = PromptModel(
        questionNumber: 1,
        question: 'Test question',
        required: true,
        responseType: ResponseType.radio,
        option: Options(type: OptionsType.radio),
        multipleAnswer: false,
      );

      final prompt3 = PromptModel(
        questionNumber: 1,
        question: 'Test question',
        required: true,
        responseType: ResponseType.radio,
        option: Options(type: OptionsType.slider),
        multipleAnswer: false,
      );

      expect(prompt1.isEffectivelyEqual(prompt2), isTrue);
      expect(prompt1.isEffectivelyEqual(prompt3), isFalse);
    });
  });

  group('NotificationComparison Tests', () {
    test('isEffectivelyEqual should compare notifications correctly', () {
      final now = DateTime.now();
      final notification1 = Notification(
        title: 'Test title',
        body: 'Test body',
        date: now,
      );

      final notification2 = Notification(
        title: 'Test title',
        body: 'Test body',
        date: now,
      );

      final notification3 = Notification(
        title: 'Different title',
        body: 'Test body',
        date: now,
      );

      expect(notification1.isEffectivelyEqual(notification2), isTrue);
      expect(notification1.isEffectivelyEqual(notification3), isFalse);
    });
  });

  group('DiaryModelComparison Tests', () {
    test('isEffectivelyEqual should compare diaries correctly', () {
      final now = DateTime.now();
      final prompt = PromptModel(
        questionNumber: 1,
        question: 'Test question',
        required: true,
        responseType: ResponseType.audio,
        multipleAnswer: false,
      );

      final notification = Notification(
        title: 'Test title',
        body: 'Test body',
        date: now,
      );

      final diary1 = DiaryModel(
        id: 1,
        studyID: 123,
        name: 'Test Diary',
        start: now,
        end: now.add(const Duration(days: 1)),
        due: now.add(const Duration(hours: 12)),
        entries: 0,
        currentEntry: 0,
        prompts: [prompt],
        notifications: [notification],
        tags: [],
        status: DiaryStatus.idle,
        activeDays: [],
      );

      final diary2 = DiaryModel(
        id: 1,
        studyID: 123,
        name: 'Test Diary',
        start: now,
        end: now.add(const Duration(days: 1)),
        due: now.add(const Duration(hours: 12)),
        entries: 0,
        currentEntry: 0,
        prompts: [prompt],
        notifications: [notification],
        tags: [],
        status: DiaryStatus.idle,
        activeDays: [],
      );

      final diary3 = DiaryModel(
        id: 1,
        studyID: 123,
        name: 'Different Diary',
        start: now,
        end: now.add(const Duration(days: 1)),
        due: now.add(const Duration(hours: 12)),
        entries: 0,
        currentEntry: 0,
        prompts: [prompt],
        notifications: [notification],
        tags: [],
        status: DiaryStatus.idle,
        activeDays: [],
      );

      expect(diary1.isEffectivelyEqual(diary2), isTrue);
      expect(diary1.isEffectivelyEqual(diary3), isFalse);
    });

    test('isEffectivelyEqual should handle different prompt orders', () {
      final now = DateTime.now();
      final prompt1 = PromptModel(
        questionNumber: 1,
        question: 'Question 1',
        required: true,
        responseType: ResponseType.audio,
        multipleAnswer: false,
      );

      final prompt2 = PromptModel(
        questionNumber: 2,
        question: 'Question 2',
        required: true,
        responseType: ResponseType.audio,
        multipleAnswer: false,
      );

      final diary1 = DiaryModel(
        id: 1,
        studyID: 123,
        name: 'Test Diary',
        start: now,
        end: now.add(const Duration(days: 1)),
        due: now.add(const Duration(hours: 12)),
        entries: 0,
        currentEntry: 0,
        prompts: [prompt1, prompt2],
        notifications: [],
        tags: [],
        status: DiaryStatus.idle,
        activeDays: [],
      );

      final diary2 = DiaryModel(
        id: 1,
        studyID: 123,
        name: 'Test Diary',
        start: now,
        end: now.add(const Duration(days: 1)),
        due: now.add(const Duration(hours: 12)),
        entries: 0,
        currentEntry: 0,
        prompts: [prompt2, prompt1],
        notifications: [],
        tags: [],
        status: DiaryStatus.idle,
        activeDays: [],
      );

      expect(diary1.isEffectivelyEqual(diary2), isFalse);
    });
  });
}
