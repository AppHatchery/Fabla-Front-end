import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/questions_entity.dart';
import 'package:equatable/equatable.dart';

class Questions extends Equatable {
  final int id;
  final String title;
  final String subtitle;
  final List<String>? options;
  final String type;
  final int? min;
  final int? max;
  final dynamic defaultValue;
  final String? answer;

  Questions(
      {required this.id,
      required this.title,
      required this.subtitle,
      required this.options,
      required this.type,
      required this.min,
      required this.max,
      required this.defaultValue,
      required this.answer});

  factory Questions.fromJson(Map<String, dynamic> json) {
    return Questions(
        id: json['id'],
        title: json['title'],
        subtitle: json['subtitle'],
        options:
            json['options'] != null ? List<String>.from(json['options']) : null,
        type: json['type'],
        min: json['min_value'],
        max: json['max_value'],
        defaultValue: json['default_value'],
        answer: null);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'options': options,
      'type': type,
      'min_value': min,
      'max_value': max,
      'default_value': defaultValue,
      'answer': answer
    };
  }

  factory Questions.fromEntity(QuestionsEntity entity) {
    return Questions(
        id: entity.id,
        title: entity.title,
        subtitle: entity.subtitle,
        options: entity.options,
        type: entity.type,
        min: entity.min,
        max: entity.max,
        defaultValue: entity.defaultValue,
        answer: entity.answer);
  }

  Questions copyWith({
    int? id,
    String? title,
    String? subtitle,
    List<String>? options,
    String? type,
    int? min,
    int? max,
    dynamic defaultValue,
    String? answer,
  }) {
    return Questions(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      options: options ?? this.options,
      type: type ?? this.type,
      min: min ?? this.min,
      max: max ?? this.max,
      defaultValue: defaultValue ?? this.defaultValue,
      answer: answer,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, subtitle, options, type, min, max, defaultValue, answer];
}
