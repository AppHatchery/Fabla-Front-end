import 'package:audio_diaries_flutter/core/utils/statuses.dart';

import '../domain/entities/diary_entity.dart';
import 'prompt.dart';
import 'tag.dart';

class DiaryModel {
  final int id;
  List<Tag> tags;
  DiaryStatus status;
  DateTime due;
  final DateTime start;
  final DateTime end;
  final int entries;
  final int currentEntry;
  final List<PromptModel> prompts;

  DiaryModel({
    required this.id,
    required this.prompts,
    required this.tags,
    required this.status,
    required this.due,
    required this.start,
    required this.entries,
    required this.currentEntry,
    required this.end,
  });

  /// Factory constructor that creates a Diary object from a DiaryEntity.
  /// This function generates a Diary instance using data from a provided DiaryEntity object.
  ///
  /// Parameters:
  /// - [entity]: The DiaryEntity object containing data to populate the new Diary instance.
  ///
  /// Returns:
  /// A Diary object representing a diary entry, constructed using information from the provided DiaryEntity.
  ///
  factory DiaryModel.fromEntity(Diary entity) {
    final _prompts = entity.prompts.map((prompt) => PromptModel.fromEntity(prompt)).toList();
    return DiaryModel(
      id: entity.id,
      prompts: _prompts,
      tags: [],
      status: entity.status ?? DiaryStatus.idle,
      due: entity.due,
      start: entity.start,
      entries: entity.entries,
      currentEntry: entity.currentEntry,
      end: entity.end,
    );
  }

   DiaryModel copyWith(
      {
      required int id,
      List<PromptModel>? prompts,
      List<Tag>? tags,
      DiaryStatus? status,
      DateTime? due,
      int? currentEntry,
      DateTime? start}) {
        print("ID IJA IYI: $id");
    return DiaryModel(
      id: id,
      prompts: prompts ?? this.prompts,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      due: due ?? this.due,
      start: start ?? this.start,
      entries: entries,
      currentEntry: currentEntry ?? this.currentEntry,
      end: end,
    );
  }
}
