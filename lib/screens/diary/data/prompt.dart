import 'dart:convert';

import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/options.dart';

import '../domain/entities/answer.dart';
import '../domain/entities/prompt_entity.dart';
import 'tip.dart';

class PromptModel {
  int id;
  String question;
  ResponseType? responseType;
  Answer? answer;
  Options? option;
  bool required = true;
  String? subtitle;

  PromptModel(
      {this.id = 0,
      required this.question,
      required this.responseType,
      this.answer,
      this.option,
      required this.required,
      this.subtitle});

  /// Creates a new Prompt object with optional modifications.
  /// This method generates a new Prompt instance based on the current prompt object while allowing specific properties to be updated or changed.
  ///
  /// Parameters:
  /// - [question]: An optional string representing a modified question for the new prompt.
  /// - [responseType]: An optional ResponseType indicating an updated response type for the new prompt.
  /// - [note]: An optional string representing a modified note for the new prompt.
  /// - [tip]: An optional Tip object providing an updated tip for the new prompt.
  /// - [answer]: An optional Answer object offering a modified answer for the new prompt.
  ///
  /// Returns:
  /// A new Prompt object with the specified modifications or the same values if no modifications are provided.
  ///
  PromptModel copyWith({
    String? question,
    ResponseType? responseType,
    String? note,
    Tip? tip,
    Answer? answer,
    Options? option,
    String? subtitle,
  }) {
    return PromptModel(
      id: id,
        question: question ?? this.question,
        responseType: responseType ?? this.responseType,
        answer: answer ?? this.answer,
        option: option ?? this.option,
        subtitle: subtitle ?? this.subtitle,
        required: required);
  }

  factory PromptModel.fromEntity(Prompt prompt) {
    final model =  PromptModel(
        id: prompt.id,
        question: prompt.question,
        responseType: prompt.responseType,
        answer: null,
        option: prompt.option != null
            ? Options.fromJson(jsonDecode(prompt.option!))
            : null,
        required: prompt.required,
        subtitle: prompt.subtitle);
    return model;
  }

  factory PromptModel.fromJson(Map<String, dynamic> json) {
    return PromptModel(
       id: json['id'] ?? 0,
        question: json['title'],
        responseType: responseTypeString(json['type']),
        answer: null,
        option: Options(
            type: optionTypeFromResponse(responseTypeString(json['type'])),
            choices: json['options'] != null
                ? List<String>.from(json['options'])
                : null,
            minValue: json['min_value'],
            maxValue: json['max_value'],
            minLabel: json['min_label'],
            maxLabel: json['max_label'],
            defaultValue: json['default_value']),
        required: json['required'] == 1 ? true : false,
        subtitle: json['subtitle']);
  }
}
