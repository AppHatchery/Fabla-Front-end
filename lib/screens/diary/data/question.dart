import 'package:audio_diaries_flutter/core/utils/formatter.dart';

import '../../../core/utils/types.dart';

/// This class represents a question in the diary blueprint.
class QuestionModel {
  final String title;
  final String? subtitle;
  final bool required;
  final ResponseType responseType;
  final List<String>? options;
  final int? min;
  final int? max;
  final int? defaultValue;

  QuestionModel({
    required this.title,
    this.subtitle,
    required this.required,
    required this.responseType,
    this.options,
    this.min,
    this.max,
    this.defaultValue,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      title: json['title'],
      subtitle: json['subtitle'],
      required: json['required'],
      responseType: responseTypeString(json['type']),
      options:
          json['options'] != null ? List<String>.from(json['options']) : null,
      min: json['min_value'],
      max: json['max_value'],
      defaultValue: json['default_value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'required': required,
      'type': responseTypeValue(responseType),
      'options': options,
      'min_value': min,
      'max_value': max,
      'default_value': defaultValue,
    };
  }
}
