import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audio_diaries_flutter/core/utils/extensions.dart';
import 'package:audio_diaries_flutter/screens/diary/data/notification.dart';

import '../../dummy_data.dart';

void main() {
  group('PromptModelComparison Tests', () {
    test('isEffectivelyEqual should compare prompts correctly', () {
    
      final prompt1 = createTestPromptModel(
        id: 1, 
        questionNumber: 1, 
        question: TestValues.testName,
        required: true,
      );

      final prompt2 = createTestPromptModel(
        id: 999, 
        questionNumber: 888, 
        question: TestValues.testName, 
        required: true, 
      );

      final prompt3 = createTestPromptModel(
        question: TestValues.testDescription, 
        required: true,
      );

      expect(prompt1.isEffectivelyEqual(prompt2),
          isTrue); 
      expect(
          prompt1.isEffectivelyEqual(prompt3), isFalse); 
    });

    test('isEffectivelyEqual should handle different required values', () {
      final prompt1 = createTestPromptModel(
        question: TestValues.testName,
        required: true,
      );

      final prompt2 = createTestPromptModel(
        question: TestValues.testName,
        required: false, 
      );

      expect(prompt1.isEffectivelyEqual(prompt2), isFalse);
    });
  });

  group('NotificationComparison Tests', () {
    test('isEffectivelyEqual should compare notifications correctly', () {
      final testDate = TestDates.testDate;

      final notification1 = Notification(
        title: TestValues.testName,
        body: TestValues.testDescription,
        date: testDate,
      );

      final notification2 = Notification(
        title: TestValues.testName,
        body: TestValues.testDescription,
        date: testDate,
      );

      final notification3 = Notification(
        title: TestValues.testResponse,
        body: TestValues.testDescription,
        date: testDate,
      );

      expect(notification1.isEffectivelyEqual(notification2), isTrue);
      expect(notification1.isEffectivelyEqual(notification3), isFalse);
    });

    test('isEffectivelyEqual should handle different dates', () {
      final notification1 = Notification(
        title: TestValues.testName,
        body: TestValues.testDescription,
        date: TestDates.testDate,
      );

      final notification2 = Notification(
        title: TestValues.testName,
        body: TestValues.testDescription,
        date: TestDates.testEndDate, 
      );

      expect(notification1.isEffectivelyEqual(notification2), isFalse);
    });
  });

  group('DiaryModelComparison Tests', () {
    test('isEffectivelyEqual should compare diaries correctly', () {
      final diary1 = createTestDiaryModel(
        id: 1, 
        name: TestValues.testName, 
        start: TestDates.testDate,
        end: TestDates.testEndDate,
        due: TestDates.testEndDate,
        entries: 5,
      );

      final diary2 = createTestDiaryModel(
        id: 999, 
        name: TestValues.testName, 
        start: TestDates.testDate,
        end: TestDates.testEndDate,
        due: TestDates.testEndDate,
        entries: 5,
      );

      final diary3 = createTestDiaryModel(
        name: TestValues.testDescription, 
        start: TestDates.testDate,
        end: TestDates.testEndDate,
        due: TestDates.testEndDate,
        entries: 5,
      );

      expect(diary1.isEffectivelyEqual(diary2),
          isTrue); 
      expect(diary1.isEffectivelyEqual(diary3), isFalse); 
    });

    test('isEffectivelyEqual should handle different prompt orders', () {
      final prompt1 = createTestPromptModel(question: 'Question 1');
      final prompt2 = createTestPromptModel(question: 'Question 2');

      final baseDate = TestDates.testDate;
      final endDate = TestDates.testEndDate;

      final diary1 = createTestDiaryModel(
        name: TestValues.testName,
        start: baseDate,
        end: endDate,
        due: endDate,
        entries: 2,
        prompts: [prompt1, prompt2], 
      );

      final diary2 = createTestDiaryModel(
        name: TestValues.testName,
        start: baseDate,
        end: endDate,
        due: endDate,
        entries: 2,
        prompts: [prompt1, prompt2], 
      );

      final diary3 = createTestDiaryModel(
        name: TestValues.testName,
        start: baseDate,
        end: endDate,
        due: endDate,
        entries: 2,
        prompts: [prompt2, prompt1], 
      );

      expect(diary1.isEffectivelyEqual(diary2), isTrue);
      expect(diary1.isEffectivelyEqual(diary3), isFalse); 
    });

    test('isEffectivelyEqual should ignore status differences', () {
      final baseDate = TestDates.testDate;
      final endDate = TestDates.testEndDate;

      final diary1 = createTestDiaryModel(
        name: TestValues.testName,
        start: baseDate,
        end: endDate,
        due: endDate,
        status: DiaryStatus.idle, 
      );

      final diary2 = createTestDiaryModel(
        name: TestValues.testName,
        start: baseDate,
        end: endDate,
        due: endDate,
        status: DiaryStatus.submitted, 
      );

      expect(diary1.isEffectivelyEqual(diary2), isTrue); 
    });

    test('isEffectivelyEqual should handle different dates', () {
      final diary1 = createTestDiaryModel(
        name: TestValues.testName,
        start: TestDates.testDate, 
        end: TestDates.testEndDate,
        due: TestDates.testEndDate,
      );

      final diary2 = createTestDiaryModel(
        name: TestValues.testName,
        start: DateTime(2024, 3, 16), 
        end: TestDates.testEndDate,
        due: TestDates.testEndDate,
      );

      expect(
          diary1.isEffectivelyEqual(diary2), isFalse); 
    });

    test('isEffectivelyEqual should handle different entries count', () {
      final baseDate = TestDates.testDate;
      final endDate = TestDates.testEndDate;

      final diary1 = createTestDiaryModel(
        name: TestValues.testName,
        start: baseDate,
        end: endDate,
        due: endDate,
        entries: 5, 
      );

      final diary2 = createTestDiaryModel(
        name: TestValues.testName,
        start: baseDate,
        end: endDate,
        due: endDate,
        entries: 10, 
      );

      expect(diary1.isEffectivelyEqual(diary2), isFalse); 
    });

    test('isEffectivelyEqual should handle different studyID', () {
      final baseDate = TestDates.testDate;
      final endDate = TestDates.testEndDate;

      final diary1 = createTestDiaryModel(
        name: TestValues.testName,
        studyID: 1, 
        start: baseDate,
        end: endDate,
        due: endDate,
      );

      final diary2 = createTestDiaryModel(
        name: TestValues.testName,
        studyID: 2, 
        start: baseDate,
        end: endDate,
        due: endDate,
      );

      expect(diary1.isEffectivelyEqual(diary2), isFalse); 
    });
  });
}
