import 'dart:convert';

import '../domain/entities/protocol_entity.dart';
import 'diary_blueprint.dart';

class Protocol {
  final int version;
  final int weeklyGoal;
  final int dailyGoal;
  final List<DiaryBlueprint> diaryBlueprints;

  Protocol({
    required this.version,
    required this.weeklyGoal,
    required this.dailyGoal,
    required this.diaryBlueprints,
  });

  factory Protocol.fromJson(Map<String, dynamic> json) {
    List<DiaryBlueprint> diaryBlueprints = (json['diaries'] as List<dynamic>)
        .map<DiaryBlueprint>((e) => DiaryBlueprint.fromJson(e))
        .toList();

    return Protocol(
        version: json['version'],
        weeklyGoal: json['weekly_goal'],
        dailyGoal: json['daily_goal'],
        diaryBlueprints: diaryBlueprints);
  }

  /// This method converts the ProtocolEntity object to a Protocol object.
  ///
  /// Parameters:
  /// - [entity]: The ProtocolEntity object to be converted.
  ///
  /// Returns:
  /// A Protocol object created from the ProtocolEntity instance.
  factory Protocol.fromEntity(ProtocolEntity entity) {
    return Protocol(
        version: entity.version,
        weeklyGoal: entity.weeklyGoal,
        dailyGoal: entity.dailyGoal,
        diaryBlueprints: entity.diaryBlueprints.map((e) {
          final json = jsonDecode(e);
          return DiaryBlueprint.fromJson(json);
        }).toList());
  }

  Protocol copyWith({
    int? version,
    int? weeklyGoal,
    int? dailyGoal,
    List<DiaryBlueprint>? diaryBlueprints,
  }) {
    return Protocol(
      version: version ?? this.version,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      diaryBlueprints: diaryBlueprints ?? this.diaryBlueprints,
    );
  }
}
