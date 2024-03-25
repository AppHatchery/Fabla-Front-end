import 'package:audio_diaries_flutter/screens/diary/domain/entities/prompt_entity.dart';
import 'package:objectbox/objectbox.dart';

import 'recording.dart';

@Entity()
class Answer {
  @Id()
  int id;
  @Property(type: PropertyType.date)
  DateTime date;
  String? response;
  //List<Recording> recordings;
  @Backlink('answer')
  final recordings = ToMany<Recording>();
  final prompt = ToOne<Prompt>();
  Answer({required this.id, required this.date, this.response});

  /// Creates a new Answer object with optional modifications.
  /// This method generates a new Answer instance based on the current answer object while allowing specific properties to be updated or changed.
  ///
  /// Parameters:
  /// - [date]: An optional DateTime representing a modified date for the new answer.
  /// - [response]: An optional string representing a modified response for the new answer.
  /// - [id]: An optional integer indicating an updated identifier for the new answer.
  ///
  /// Returns:
  /// A new Answer object with the specified modifications or the same values if no modifications are provided.
  ///
  Answer copyWith({
    DateTime? date,
    String? response,
    int? id,
  }) {
    return Answer(
      id: id ?? this.id,
      date: date ?? this.date,
      response: response ?? this.response,
    );
  }
}
