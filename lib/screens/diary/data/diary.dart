import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';

import '../../../core/utils/dummy_data.dart';
import '../domain/entities/diary_entity.dart';
import 'prompt.dart';
import 'tag.dart';

class Diary {
  int id;
  List<Prompt> prompts;
  List<Tag> tags;
  DiaryStatus status;
  DateTime due;
  DateTime start;

  Diary(
      {required this.id,
      required this.prompts,
      required this.tags,
      required this.status,
      required this.due,
      required this.start});

  /// Factory constructor that creates a Diary object from a DiaryEntity.
  /// This function generates a Diary instance using data from a provided DiaryEntity object.
  ///
  /// Parameters:
  /// - [entity]: The DiaryEntity object containing data to populate the new Diary instance.
  ///
  /// Returns:
  /// A Diary object representing a diary entry, constructed using information from the provided DiaryEntity.
  ///
  factory Diary.fromEntity(DiaryEntity entity) {
    final date = DateTime.parse(entity.deadline);
    final start = DateTime.parse(entity.start);
    final tag = Tag(
        text: switch (entity.status) {
          DiaryStatus.idle => "Idle",
          DiaryStatus.ongoing => "Ongoing",
          DiaryStatus.complete => "Ongoing",
          DiaryStatus.submitted => "Done",
          DiaryStatus.missed => "Missed",
          null => "Idle"
        },
        type: TagType.time);
    return Diary(
        id: entity.id,
        prompts: fakePrompts[entity.prompts[0]] ?? [],
        tags: [tag],
        status: entity.status ?? DiaryStatus.idle,
        due: date,
        start: start);
  }
}
