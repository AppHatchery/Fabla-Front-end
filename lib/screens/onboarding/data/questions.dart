import 'dart:convert';

import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/questions_entity.dart';
import 'package:equatable/equatable.dart';

class Questions extends Equatable {
  final int id;
  final String title;
  final String? subtitle;
  final List<Option>? options;
  final String type;
  final int? min;
  final int? max;
  final int? defaultValue;
  final String variable;
  final String? answer;

  const Questions(
      {required this.id,
      required this.title,
      required this.subtitle,
      required this.options,
      required this.type,
      required this.min,
      required this.max,
      required this.defaultValue,
      required this.variable,
      required this.answer});

  factory Questions.fromJson(Map<String, dynamic> json) {
    return Questions(
        id: json['id'],
        title: json['title'],
        subtitle: json['subtitle'],
        options: json['options'] != null ? (json['options'] as List<dynamic>)
            .map((element) => Option.fromJson(element))
            .toList() : null,
        type: json['type'],
        min: json['min_value'],
        max: json['max_value'],
        defaultValue: json['default_value'],
        variable: json['variable'],
        answer: null);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'options':
          json.encode(options?.map((element) => element.toJson()).toList()),
      'type': type,
      'min_value': min,
      'max_value': max,
      'default_value': defaultValue,
      'variable': variable,
      'answer': answer
    };
  }

  factory Questions.fromEntity(QuestionsEntity entity) {
    return Questions(
        id: entity.id,
        title: entity.title,
        subtitle: entity.subtitle,
        options:entity.options != null ? (jsonDecode(entity.options!) as List<dynamic>)
            .map((element) => Option.fromJson(element))
            .toList() : null,
        type: entity.type,
        min: entity.min,
        max: entity.max,
        defaultValue: entity.defaultValue,
        variable: entity.variable,
        answer: entity.answer);
  }

  Questions copyWith({
    int? id,
    String? title,
    String? subtitle,
    List<Option>? options,
    String? type,
    int? min,
    int? max,
    int? defaultValue,
    String? variable,
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
      variable: variable ?? this.variable,
      answer: answer,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        options,
        type,
        min,
        max,
        defaultValue,
        variable,
        answer
      ];
}

class Option {
  final String title;
  final dynamic value;

  Option({required this.title, required this.value});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(title: json['title'], value: json['value']);
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'value': value};
  }
}
