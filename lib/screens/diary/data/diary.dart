import 'dart:convert';

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/notification.dart';

import '../domain/entities/diary_entity.dart';
import 'prompt.dart';
import 'tag.dart';

class DiaryModel implements Comparable<DiaryModel> {
  final int id;
  final int studyID;
  final String name;
  List<Tag>? tags;
  DiaryStatus status;
  DateTime due;
  final DateTime start;
  final DateTime end;
  final int entries;
  final int currentEntry;
  final List<PromptModel> prompts;
  final List<Notification> notifications;
  final List<int>? activeDays;
  final List<DateTime>? submissions;

  DiaryModel(
      {required this.id,
      required this.studyID,
      required this.name,
      required this.prompts,
      required this.tags,
      required this.status,
      required this.due,
      required this.start,
      required this.entries,
      required this.currentEntry,
      required this.end,
      required this.notifications,
      required this.activeDays,
      required this.submissions});

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
        studyID: entity.studyID,
        name: entity.name,
        prompts: _prompts,
        tags: null,
        status: entity.status ?? DiaryStatus.idle,
        due: entity.due,
        start: entity.start,
        entries: entity.entries,
        currentEntry: entity.currentEntry,
        end: entity.end,
        notifications: json
            .decode(entity.notifications)
            .map<Notification>((e) => Notification.fromEntity(e))
            .toList(),
        activeDays: entity.activeDays,
        submissions: entity.submissions
            ?.map((submission) => DateTime.parse(submission))
            .toList());
  }

  factory DiaryModel.fromJson(Map<String, dynamic> json, int studyID) {
    return DiaryModel(
        id: 0,
        studyID: studyID,
        name: json['name'],
        prompts: (json['questions'] as List)
            .map((prompt) => PromptModel.fromJson(prompt))
            .toList(),
        tags: null,
        status: DiaryStatus.idle,
        due: DateTime.parse(json['end_time']).toLocal(),
        start: DateTime.parse(json['start_time']).toLocal(),
        entries: json['entries'],
        currentEntry: 0,
        end: DateTime.parse(json['end_time']).toLocal(),
        notifications: (json['notifications'] as List?)
                ?.map((e) => Notification.fromJson(
                    e, DateTime.parse(json['start_time'])))
                .toList() ??
            [],
        activeDays: (json['active_days'] as List<dynamic>?)?.map((e) {
          final day = e as int;
          return day == 0 ? 7 : day;
        }).toList(),
        submissions: null);
  }

  DiaryModel copyWith(
      {required int id,
      required int studyID,
      String? name,
      List<PromptModel>? prompts,
      List<Tag>? tags,
      DiaryStatus? status,
      DateTime? due,
      int? currentEntry,
      DateTime? start,
      List<Notification>? notifications,
      List<int>? activeDays,
      List<DateTime>? submissions}) {
    return DiaryModel(
        id: id,
        studyID: studyID,
        name: name ?? this.name,
        prompts: prompts ?? this.prompts,
        tags: tags ?? this.tags,
        status: status ?? this.status,
        due: due ?? this.due,
        start: start ?? this.start,
        entries: entries,
        currentEntry: currentEntry ?? this.currentEntry,
        end: due ?? end,
        notifications: notifications ?? this.notifications,
        activeDays: activeDays,
        submissions: submissions);
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
