import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';

import '../domain/entities/diary_entity.dart';
import 'prompt.dart';
import 'tag.dart';

class DiaryModel implements Comparable<DiaryModel> {
  final int id;
  final DairyType type;
  List<Tag>? tags;
  DiaryStatus status;
  DateTime due;
  final DateTime start;
  final DateTime end;
  final int entries;
  final int currentEntry;
  final List<PromptModel> prompts;

  DiaryModel({
    required this.id,
    required this.type,
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
    final _prompts =
        entity.prompts.map((prompt) => PromptModel.fromEntity(prompt)).toList();
    return DiaryModel(
      id: entity.id,
      type: entity.type ?? DairyType.daily,
      prompts: _prompts,
      tags: null,
      status: entity.status ?? DiaryStatus.idle,
      due: entity.due,
      start: entity.start,
      entries: entity.entries,
      currentEntry: entity.currentEntry,
      end: entity.end,
    );
  }

  factory DiaryModel.fromJson(dynamic json) {
    return DiaryModel(
      id: 0,
      type: diaryTypeString(json['type_']),
      prompts: List<dynamic>.from(json['questions'])
          .map((question) => PromptModel.fromJson(question))
          .toList(),
      tags: null,
      status: DiaryStatus.idle,
      due: DateTime.parse(json['end_time']),
      start: DateTime.parse(json['start_time']),
      entries: json['entries'] ?? 1,
      currentEntry: 0,
      end: DateTime.parse(json['end_time']),
    );
  }

  DiaryModel copyWith(
      {required int id,
      DairyType? type,
      List<PromptModel>? prompts,
      List<Tag>? tags,
      DiaryStatus? status,
      DateTime? due,
      int? currentEntry,
      DateTime? start}) {
    return DiaryModel(
      id: id,
      type: type ?? this.type,
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

  /// Compares this DiaryModel object with another DiaryModel object.
  ///
  /// This function compares two DiaryModel objects based on their status values.
  /// It assigns numerical values to DiaryStatus enum values and uses them for comparison.
  ///
  /// Parameters:
  /// - [other]: The DiaryModel object to compare with.
  ///
  /// Returns:
  /// -1 if this DiaryModel's status is less than the other's status,
  ///  0 if their statuses are equal,
  ///  1 if this DiaryModel's status is greater than the other's status.
  @override
  int compareTo(DiaryModel other) {
    Map<DiaryStatus, int> statusValues = {
      DiaryStatus.idle: 0,
      DiaryStatus.ongoing: 1,
      DiaryStatus.complete: 2,
      DiaryStatus.submitted: 3,
      DiaryStatus.missed: 4
    };

    // Compare objects based on status values
    return statusValues[status]!.compareTo(statusValues[other.status]!);
  }
}
