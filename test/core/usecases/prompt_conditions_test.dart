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

  group('contains / notContains', () {
    test('contains matches a substring', () {
      final c = condition(ConditionType.contains, 'Anxious');
      expect(c.evaluate(answerOf('Calm/ Anxious')), isTrue);
      expect(c.evaluate(answerOf('Calm')), isFalse);
      expect(c.evaluate(null), isFalse);
    });

    test('contains with a list requires every value', () {
      final c = condition(ConditionType.contains, ['Calm', 'Tired']);
      expect(c.evaluate(answerOf('Calm/ Tired/ Happy')), isTrue);
      expect(c.evaluate(answerOf('Calm/ Happy')), isFalse);
    });

    test('notContains is true when the value is absent or unanswered', () {
      final c = condition(ConditionType.notContains, 'Anxious');
      expect(c.evaluate(answerOf('Calm')), isTrue);
      expect(c.evaluate(answerOf('Anxious')), isFalse);
      expect(c.evaluate(null), isTrue);
    });

    test('notContains with a list requires none of the values', () {
      final c = condition(ConditionType.notContains, ['Calm', 'Tired']);
      expect(c.evaluate(answerOf('Happy')), isTrue);
      expect(c.evaluate(answerOf('Happy/ Tired')), isFalse);
    });
  });

  group('answered / notAnswered', () {
    test('answered needs a non-blank response', () {
      final c = condition(ConditionType.answered, null);
      expect(c.evaluate(answerOf('Yes')), isTrue);
      expect(c.evaluate(answerOf('   ')), isFalse);
      expect(c.evaluate(Answer(id: 0, date: DateTime(2026))), isFalse);
      expect(c.evaluate(null), isFalse);
    });

    test('notAnswered is the inverse', () {
      final c = condition(ConditionType.notAnswered, null);
      expect(c.evaluate(null), isTrue);
      expect(c.evaluate(answerOf('Yes')), isFalse);
    });
  });

  group('numeric comparisons', () {
    test('greaterThan accepts numeric and string expected values', () {
      expect(condition(ConditionType.greaterThan, 5).evaluate(answerOf('7')),
          isTrue);
      expect(condition(ConditionType.greaterThan, '5').evaluate(answerOf('5')),
          isFalse);
      expect(condition(ConditionType.greaterThan, 2.5).evaluate(answerOf('3.0')),
          isTrue);
    });

    test('lessThan compares numerically', () {
      expect(condition(ConditionType.lessThan, 5).evaluate(answerOf('4.5')),
          isTrue);
      expect(condition(ConditionType.lessThan, 5).evaluate(answerOf('5')),
          isFalse);
    });

    test('non-numeric or missing values are false', () {
      expect(condition(ConditionType.greaterThan, 5).evaluate(answerOf('abc')),
          isFalse);
      expect(condition(ConditionType.lessThan, 5).evaluate(answerOf('abc')),
          isFalse);
      expect(condition(ConditionType.greaterThan, true).evaluate(answerOf('1')),
          isFalse);
      expect(condition(ConditionType.greaterThan, 5).evaluate(null), isFalse);
      expect(condition(ConditionType.lessThan, 5).evaluate(null), isFalse);
    });

    test('between is inclusive of min and max', () {
      final c = condition(ConditionType.between, {'min': 3, 'max': 7});
      expect(c.evaluate(answerOf('3')), isTrue);
      expect(c.evaluate(answerOf('7')), isTrue);
      expect(c.evaluate(answerOf('5.5')), isTrue);
      expect(c.evaluate(answerOf('8')), isFalse);
      expect(c.evaluate(answerOf('abc')), isFalse);
      expect(c.evaluate(null), isFalse);
    });

    test('between needs a map with min and max', () {
      expect(condition(ConditionType.between, 5).evaluate(answerOf('5')),
          isFalse);
      expect(
          condition(ConditionType.between, {'min': 1}).evaluate(answerOf('5')),
          isFalse);
    });
  });

  group('time comparisons', () {
    test('beforeTime and afterTime compare HH:mm strings', () {
      expect(condition(ConditionType.beforeTime, '12:00')
          .evaluate(answerOf('09:30')), isTrue);
      expect(condition(ConditionType.beforeTime, '12:00')
          .evaluate(answerOf('12:00')), isFalse);
      expect(condition(ConditionType.afterTime, '12:00')
          .evaluate(answerOf('12:01')), isTrue);
      expect(condition(ConditionType.afterTime, '12:00')
          .evaluate(answerOf('11:59')), isFalse);
    });

    test('compares hours before minutes', () {
      expect(condition(ConditionType.afterTime, '09:45')
          .evaluate(answerOf('10:05')), isTrue);
    });

    test('accepts an expected value as an hour/minute map', () {
      final c =
          condition(ConditionType.beforeTime, {'hour': 21, 'minute': 30});
      expect(c.evaluate(answerOf('21:15')), isTrue);
      expect(c.evaluate(answerOf('22:00')), isFalse);
    });

    test('unparseable or missing times are false', () {
      expect(condition(ConditionType.beforeTime, '12:00')
          .evaluate(answerOf('noon')), isFalse);
      expect(condition(ConditionType.afterTime, 12).evaluate(answerOf('13:00')),
          isFalse);
      expect(condition(ConditionType.beforeTime, '12:00').evaluate(null),
          isFalse);
      expect(condition(ConditionType.afterTime, '12:00').evaluate(null),
          isFalse);
    });
  });
}
