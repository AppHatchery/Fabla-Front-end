import 'package:audio_diaries_flutter/core/utils/statuses.dart';

import '../../../core/utils/dummy_data.dart';
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
  final List<PromptModel> prompts;

  DiaryModel({
    required this.id,
    required this.prompts,
    required this.tags,
    required this.status,
    required this.due,
    required this.start,
    required this.entries,
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
    return DiaryModel(
      id: entity.id,
      prompts: fakePrompts[entity.prompts[0]] ?? [],
      tags: [],
      status: entity.status ?? DiaryStatus.idle,
      due: entity.due,
      start: entity.start,
      entries: entity.entries,
      end: entity.end,
    );
  }

  factory DiaryModel.copyWith(
      {DiaryModel? diary,
      int? id,
      List<PromptModel>? prompts,
      List<Tag>? tags,
      DiaryStatus? status,
      DateTime? due,
      DateTime? start}) {
    return DiaryModel(
      id: id ?? diary!.id,
      prompts: prompts ?? diary!.prompts,
      tags: tags ?? diary!.tags,
      status: status ?? diary!.status,
      due: due ?? diary!.due,
      start: start ?? diary!.start,
      entries: diary!.entries,
      end: diary.end,
    );
  }
}
