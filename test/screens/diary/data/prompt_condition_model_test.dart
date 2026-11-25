import 'dart:convert';

import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/condition.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/answer.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/prompt_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Answer answerOf(String response) =>
      Answer(id: 0, date: DateTime(2026), response: [response]);

  PromptModel promptWith({
    List<PromptCondition>? conditions,
    ConditionLogic? logic,
  }) =>
      PromptModel(
        questionNumber: 3,
        question: 'Q3',
        responseType: ResponseType.text,
        required: false,
        multipleAnswer: false,
        conditions: conditions,
        conditionLogic: logic,
      );

  PromptCondition equalsOn(int target, String value) => PromptCondition(
      targetPrompt: target,
      conditionType: ConditionType.equals,
      expectedValue: value);

  group('parseConditionType / conditionTypeToString', () {
    test('round-trips every condition type', () {
      for (final type in ConditionType.values) {
        expect(parseConditionType(conditionTypeToString(type)), type);
      }
    });

    test('accepts camelCase, snake_case and any letter case', () {
      expect(parseConditionType('notEquals'), ConditionType.notEquals);
      expect(parseConditionType('not_equals'), ConditionType.notEquals);
      expect(parseConditionType('GREATER_THAN'), ConditionType.greaterThan);
      expect(parseConditionType('notContains'), ConditionType.notContains);
      expect(parseConditionType('notAnswered'), ConditionType.notAnswered);
      expect(parseConditionType('lessThan'), ConditionType.lessThan);
      expect(parseConditionType('beforeTime'), ConditionType.beforeTime);
      expect(parseConditionType('afterTime'), ConditionType.afterTime);
    });

    test('falls back to equals for unknown types', () {
      expect(parseConditionType('unknown'), ConditionType.equals);
    });
  });

  group('PromptCondition JSON', () {
    test('fromJson reads the protocol shape', () {
      final c = PromptCondition.fromJson({
        'target_question_number': 2,
        'condition_type': 'equals',
        'expected_value': 'Complete',
      });

      expect(c.id, 0);
      expect(c.targetPrompt, 2);
      expect(c.conditionType, ConditionType.equals);
      expect(c.expectedValue, 'Complete');
    });

    test('toJson round-trips through fromJson', () {
      final original = PromptCondition(
        id: 7,
        targetPrompt: 4,
        conditionType: ConditionType.between,
        expectedValue: {'min': 1, 'max': 5},
      );

      final json = original.toJson();
      expect(json['condition_type'], 'between');

      final restored = PromptCondition.fromJson(json);
      expect(restored.id, 7);
      expect(restored.targetPrompt, 4);
      expect(restored.conditionType, ConditionType.between);
      expect(restored.expectedValue, {'min': 1, 'max': 5});
    });
  });

  group('PromptModel.shouldShow', () {
    test('always shows a prompt without conditions', () {
      expect(promptWith().shouldShow({}), isTrue);
      expect(promptWith(conditions: []).shouldShow({}), isTrue);
    });

    test('defaults to AND when no logic is set', () {
      final prompt =
          promptWith(conditions: [equalsOn(1, 'Yes'), equalsOn(2, 'Complete')]);

      expect(
          prompt.shouldShow(
              {1: answerOf('Yes'), 2: answerOf('timer| Complete')}),
          isTrue);
      expect(prompt.shouldShow({1: answerOf('Yes')}), isFalse);
    });

    test('OR shows the prompt when any condition is met', () {
      final prompt = promptWith(
        conditions: [equalsOn(1, 'Yes'), equalsOn(2, 'Complete')],
        logic: ConditionLogic.or,
      );

      expect(prompt.shouldShow({2: answerOf('Complete')}), isTrue);
      expect(prompt.shouldShow({1: answerOf('No')}), isFalse);
    });
  });

  group('PromptModel conditions parsing', () {
    test('fromJson reads conditions and condition_logic', () {
      final model = PromptModel.fromJson({
        'question_id': 3003,
        'type': 'text',
        'title': 'Q3: How was your meditation?',
        'required': false,
        'question_number': 3,
        'conditions': [
          {
            'target_question_number': 2,
            'condition_type': 'equals',
            'expected_value': 'Complete',
          }
        ],
        'condition_logic': 'or',
      });

      expect(model.conditions, hasLength(1));
      expect(model.conditions!.first.targetPrompt, 2);
      expect(model.conditionLogic, ConditionLogic.or);
    });

    test('fromJson leaves conditions null when absent', () {
      final model = PromptModel.fromJson({
        'type': 'text',
        'title': 'Q1',
        'required': true,
        'question_number': 1,
      });

      expect(model.conditions, isNull);
      expect(model.conditionLogic, isNull);
    });

    // Built through fromJson, like protocol prompts, so `option` is set —
    // fromEntity can't decode an entity whose option was saved as null.
    PromptModel protocolPrompt([Map<String, dynamic> extra = const {}]) =>
        PromptModel.fromJson({
          'type': 'text',
          'title': 'Q3',
          'required': false,
          'question_number': 3,
          ...extra,
        });

    test('conditions survive a round trip through the entity', () {
      final model = protocolPrompt({
        'conditions': [
          {
            'target_question_number': 2,
            'condition_type': 'equals',
            'expected_value': 'Complete',
          }
        ],
        'condition_logic': 'and',
      });

      final entity = Prompt.fromModel(model);
      expect(jsonDecode(entity.conditions!), isA<List>());
      expect(entity.conditionLogic, ConditionLogic.and.index);

      final restored = PromptModel.fromEntity(entity);
      expect(restored.conditions, hasLength(1));
      expect(restored.conditions!.first.expectedValue, 'Complete');
      expect(restored.conditionLogic, ConditionLogic.and);

      // copyWith keeps the conditions.
      final copy = restored.copyWith(question: 'Renamed');
      expect(copy.conditions, hasLength(1));
      expect(copy.conditionLogic, ConditionLogic.and);
    });

    test('an entity without conditions maps to null', () {
      final restored = PromptModel.fromEntity(Prompt.fromModel(protocolPrompt()));
      expect(restored.conditions, isNull);
      expect(restored.conditionLogic, isNull);
    });
  });
}
