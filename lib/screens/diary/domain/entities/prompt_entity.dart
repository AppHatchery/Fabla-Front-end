import 'dart:convert';

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

  set responseTypeValue(int? index) {
    _ensureResponseType();
    responseType = ResponseType.values[index ?? 0];
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
    assert(ResponseType.recording.index == 0);
    assert(ResponseType.text.index == 1);
    assert(ResponseType.multiple.index == 2);
    assert(ResponseType.radio.index == 3);
    assert(ResponseType.slider.index == 4);
    assert(ResponseType.textAudio.index == 5);
    assert(ResponseType.webview.index == 6);
  }

  factory Prompt.fromModel(PromptModel model) {
    final entity = Prompt(
      id: model.id,
      question: model.question,
      responseType: model.responseType,
      option: jsonEncode(model.option?.toJson()),
      subtitle: model.subtitle,
      required: model.required,
    );

    if(model.answer != null){entity.answers.insert(0, model.answer!);}

    return entity;
  }
}
