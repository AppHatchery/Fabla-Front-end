import 'package:audio_diaries_flutter/core/utils/types.dart';

import '../domain/entities/answer.dart';
import 'tip.dart';

class Prompt {
  int id;
  String? question;
  ResponseType? responseType;
  String? note;
  Tip? tip;
  Answer? answer;

  Prompt(
      {this.id = 0,
      required this.question,
      required this.responseType,
      this.note,
      this.tip,
      this.answer});

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
  Prompt copyWith({
    String? question,
    ResponseType? responseType,
    String? note,
    Tip? tip,
    Answer? answer,
  }) {
    return Prompt(
      question: question ?? this.question,
      responseType: responseType ?? this.responseType,
      note: note ?? this.note,
      tip: tip ?? this.tip,
      answer: answer ?? this.answer,
    );
  }
}
