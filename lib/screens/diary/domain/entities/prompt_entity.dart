import 'dart:convert';

import 'package:audio_diaries_flutter/screens/diary/data/options.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart';
import 'package:objectbox/objectbox.dart';

import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/answer.dart';

@Entity()
class Prompt {
  @Id()
  int id = 0;
  String question;
  @Transient()
  ResponseType? responseType;
  String? option;
  String? subtitle;
  bool required;

  @Backlink('prompt')
  final answers = ToMany<Answer>();
  final diary = ToOne<Diary>();

  int? get responseTypeValue {
    _ensureResponseType();
    return responseType?.index;
  }

  set responseTypeValue(int? value) {
    _ensureResponseType();
    responseType = ResponseType.values[0];
  }

  Prompt({
    this.id = 0,
    required this.question,
    this.responseType,
    this.option,
    this.subtitle,
    this.required = true,
  });

  void _ensureResponseType() {
    assert(ResponseType.text.index == 0);
    assert(ResponseType.multiple.index == 1);
    assert(ResponseType.slider.index == 3);
    assert(ResponseType.recording.index == 2);
    assert(ResponseType.textAudio.index == 4);
    assert(ResponseType.radio.index == 5);
  }

  factory Prompt.fromModel(PromptModel model) {
    return Prompt(
      id: model.id,
      question: model.question,
      responseType: model.responseType,
      option: jsonEncode(model.option?.toJson()),
      subtitle: model.subtitle,
      required: model.required,
    );
  }
}
