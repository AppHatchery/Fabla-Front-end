import 'package:audio_diaries_flutter/core/usecases/prompt_conditions.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/condition.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/answer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Answer answerOf(String response) =>
      Answer(id: 0, date: DateTime(2026), response: [response]);

  PromptCondition condition(ConditionType type, dynamic expected) =>
      PromptCondition(
          targetPrompt: 2, conditionType: type, expectedValue: expected);

  group('equals', () {
    final equalsComplete = condition(ConditionType.equals, 'Complete');

    test('matches a single value case-insensitively', () {
      expect(equalsComplete.evaluate(answerOf('Complete')), isTrue);
      expect(equalsComplete.evaluate(answerOf('complete')), isTrue);
    });

    test('matches a timer that reached zero then was dismissed', () {
      expect(equalsComplete.evaluate(answerOf('timer| Complete')), isTrue);
    });

    test('matches a timer completed multiple times', () {
      expect(equalsComplete.evaluate(answerOf('Complete| Complete')), isTrue);
      expect(
          equalsComplete.evaluate(answerOf('timer| Complete| timer| Complete')),
          isTrue);
    });

    test('tolerates stray separators and whitespace', () {
      expect(equalsComplete.evaluate(answerOf('Complete | Complete |')), isTrue);
      expect(equalsComplete.evaluate(answerOf('| Complete')), isTrue);
    });

    test('does not match when no entry equals the expected value', () {
      expect(equalsComplete.evaluate(answerOf('timer')), isFalse);
      expect(equalsComplete.evaluate(answerOf('Completed')), isFalse);
      expect(equalsComplete.evaluate(answerOf('Incomplete| timer')), isFalse);
    });

    test('still matches an expected value that itself contains "|"', () {
      final c = condition(ConditionType.equals, 'a | b');
      expect(c.evaluate(answerOf('a | b')), isTrue);
    });

    test('is false for a missing or empty answer', () {
      expect(equalsComplete.evaluate(null), isFalse);
      expect(
          equalsComplete
              .evaluate(Answer(id: 0, date: DateTime(2026), response: null)),
          isFalse);
      expect(
          equalsComplete
              .evaluate(Answer(id: 0, date: DateTime(2026), response: [])),
          isFalse);
    });
  });

  group('notEquals', () {
    final notComplete = condition(ConditionType.notEquals, 'Complete');

    test('is false once any timer run completed', () {
      expect(notComplete.evaluate(answerOf('timer| Complete')), isFalse);
      expect(notComplete.evaluate(answerOf('Complete| Complete')), isFalse);
    });

    test('is true when the timer never completed', () {
      expect(notComplete.evaluate(answerOf('timer')), isTrue);
      expect(notComplete.evaluate(null), isTrue);
    });
  });
}
