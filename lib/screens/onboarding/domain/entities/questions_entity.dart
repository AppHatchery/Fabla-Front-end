import 'dart:convert';

import 'package:objectbox/objectbox.dart';
import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';

@Entity()
class QuestionsEntity {
  @Id()
  int id;
  final String title;
  final String? subtitle;
  final String? options;
  final String type;
  final int? min;
  final int? max;
  final int? defaultValue;
  final String? minLabel;
  final String? maxLabel;
  final String variable;
  String? answer;

  QuestionsEntity(
      {required this.id,
      required this.title,
      required this.subtitle,
      this.options,
      required this.type,
      this.min,
      this.max,
      this.defaultValue,
      this.minLabel,
      this.maxLabel,
      required this.variable,
      this.answer});

  factory QuestionsEntity.fromModel(Questions model) {
    return QuestionsEntity(
        id: model.id,
        title: model.title,
        subtitle: model.subtitle,
        options: model.options != null
            ? json.encode(
                model.options?.map((element) => element.toJson()).toList())
            : null,
        type: model.type,
        min: model.min,
        max: model.max,
        defaultValue: model.defaultValue,
        minLabel: model.minLabel,
        maxLabel: model.maxLabel,
        variable: model.variable,
        answer: model.answer);
  }
}
