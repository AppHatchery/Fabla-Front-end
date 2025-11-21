import 'package:audio_diaries_flutter/core/utils/types.dart' show ConditionType;
import 'package:audio_diaries_flutter/screens/diary/data/condition.dart'
    show PromptCondition;
import 'package:audio_diaries_flutter/screens/diary/domain/entities/answer.dart';
import 'package:flutter/material.dart' show TimeOfDay;

extension PromptConditionEvaluation on PromptCondition {
  /// Evaluates whether the condition is met based on the provided answer.
  ///
  /// Parameters:
  /// - [answer]: The Answer object to evaluate against the condition.
  ///
  /// Returns:
  /// true if the condition is met, false otherwise.
  bool evaluate(Answer? answer) {
    switch (conditionType) {
      case ConditionType.equals:
        return _evaluateEquals(answer);
      case ConditionType.notEquals:
        return _evaluateNotEquals(answer);
      case ConditionType.contains:
        return _evaluateContains(answer);
      case ConditionType.notContains:
        return _evaluateNotContains(answer);
      case ConditionType.answered:
        return _evaluateAnswered(answer);
      case ConditionType.notAnswered:
        return _evaluateNotAnswered(answer);
      case ConditionType.greaterThan:
        return _evaluateGreaterThan(answer);
      case ConditionType.lessThan:
        return _evaluateLessThan(answer);
      case ConditionType.between:
        return _evaluateBetween(answer);
      case ConditionType.beforeTime:
        return _evaluateBeforeTime(answer);
      case ConditionType.afterTime:
        return _evaluateAfterTime(answer);
    }
  }

  bool _evaluateEquals(Answer? answer) {
    if (answer == null) return false;

    // For single value answers (radio, text, etc.)
    if (answer.response != null) {
      return answer.response!.first.toLowerCase() ==
          expectedValue.toString().toLowerCase();
    }

    return false;
  }

  bool _evaluateNotEquals(Answer? answer) {
    return !_evaluateEquals(answer);
  }

  bool _evaluateContains(Answer? answer) {
    if (answer == null || answer.response == null) return false;

    // Check if the answer list contains the expected value
    if (expectedValue is List) {
      // Check if answer contains ALL values in expectedValue list
      return (expectedValue as List)
          .every((item) => answer.response!.first.contains(item));
    }

    // Check if answer contains a single expected value
    return answer.response!.first.contains(expectedValue);
  }

  bool _evaluateNotContains(Answer? answer) {
    if (answer == null || answer.response == null) return true;

    if (expectedValue is List) {
      // Check if answer contains NONE of the values in expectedValue list
      return !(expectedValue as List)
          .any((item) => answer.response!.first.contains(item));
    }

    return !answer.response!.first.contains(expectedValue);
  }

  bool _evaluateAnswered(Answer? answer) {
    if (answer == null) return false;

    // Check single value
    if (answer.response != null) {
      return answer.response!.first.trim().isNotEmpty;
    }

    return false;
  }

  bool _evaluateNotAnswered(Answer? answer) {
    return !_evaluateAnswered(answer);
  }

  bool _evaluateGreaterThan(Answer? answer) {
    if (answer == null || answer.response == null) return false;

    try {
      double answerValue = _parseNumeric(answer.response!.first);
      double expectedNumeric = _parseNumeric(expectedValue);
      return answerValue > expectedNumeric;
    } catch (e) {
      return false;
    }
  }

  bool _evaluateLessThan(Answer? answer) {
    if (answer == null || answer.response == null) return false;

    try {
      double answerValue = _parseNumeric(answer.response!.first);
      double expectedNumeric = _parseNumeric(expectedValue);
      return answerValue < expectedNumeric;
    } catch (e) {
      return false;
    }
  }

  bool _evaluateBetween(Answer? answer) {
    if (answer == null || answer.response == null) return false;
    if (expectedValue is! Map ||
        !expectedValue.containsKey('min') ||
        !expectedValue.containsKey('max')) {
      return false;
    }

    try {
      double answerValue = _parseNumeric(answer.response!.first);
      double min = _parseNumeric(expectedValue['min']);
      double max = _parseNumeric(expectedValue['max']);
      return answerValue >= min && answerValue <= max;
    } catch (e) {
      return false;
    }
  }

  // ===== TIME COMPARISON CONDITIONS =====

  bool _evaluateBeforeTime(Answer? answer) {
    if (answer == null || answer.response == null) return false;

    try {
      TimeOfDay answerTime = _parseTime(answer.response!.first);
      TimeOfDay expectedTime = _parseTime(expectedValue);
      return _compareTime(answerTime, expectedTime) < 0;
    } catch (e) {
      return false;
    }
  }

  bool _evaluateAfterTime(Answer? answer) {
    if (answer == null || answer.response == null) return false;

    try {
      TimeOfDay answerTime = _parseTime(answer.response!.first);
      TimeOfDay expectedTime = _parseTime(expectedValue);
      return _compareTime(answerTime, expectedTime) > 0;
    } catch (e) {
      return false;
    }
  }

  /// Parses a numeric value from dynamic input.
  /// Supports int, double, and numeric strings.
  double _parseNumeric(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    throw FormatException('Cannot parse numeric value: $value');
  }

  /// Parses a TimeOfDay from dynamic input.
  /// Supports TimeOfDay, "HH:mm" strings, and maps with 'hour' and 'minute' keys.
  TimeOfDay _parseTime(dynamic value) {
    if (value is TimeOfDay) return value;

    if (value is String) {
      // Parse "HH:mm" format
      final parts = value.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    if (value is Map &&
        value.containsKey('hour') &&
        value.containsKey('minute')) {
      return TimeOfDay(hour: value['hour'], minute: value['minute']);
    }

    throw FormatException('Cannot parse time value: $value');
  }

  int _compareTime(TimeOfDay a, TimeOfDay b) {
    if (a.hour != b.hour) return a.hour.compareTo(b.hour);
    return a.minute.compareTo(b.minute);
  }
}
