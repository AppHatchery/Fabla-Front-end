import 'package:audio_diaries_flutter/core/utils/formatter.dart'
    show parseConditionType, conditionTypeToString;
import 'package:audio_diaries_flutter/core/utils/types.dart';

class PromptCondition {
  int id;
  int targetPrompt; // Prompt's question number
  ConditionType conditionType;
  dynamic expectedValue; // The expected value to meet the condition

  PromptCondition({
    this.id = 0,
    required this.targetPrompt,
    required this.conditionType,
    this.expectedValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'target_question_number': targetPrompt,
      'condition_type': conditionTypeToString(conditionType),
      'expected_value': expectedValue,
    };
  }

  factory PromptCondition.fromJson(Map<String, dynamic> json) {
    return PromptCondition(
      id: json['id'] ?? 0,
      targetPrompt: json['target_question_number'],
      conditionType: parseConditionType(json['condition_type']),
      expectedValue: json['expected_value'],
    );
  }
}
