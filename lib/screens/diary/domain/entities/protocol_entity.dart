import 'dart:convert';

import 'package:audio_diaries_flutter/screens/diary/data/protocol.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class ProtocolEntity {
  @Id()
  int id = 0;
  int version;
  int weeklyGoal;
  int dailyGoal;
  List<String> diaryBlueprints;

  ProtocolEntity({
    required this.id,
    required this.version,
    required this.weeklyGoal,
    required this.dailyGoal,
    required this.diaryBlueprints,
  });

  /// This method creates a new ProtocolEntity object with updated values, where certain properties
  /// are replaced with those from the provided 'entity' parameter. Other properties are retained
  /// from the original ProtocolEntity object (this instance).
  ///
  /// Note:
  /// The 'id' property is not modified
  ProtocolEntity copyWith({required ProtocolEntity entity}) {
    return ProtocolEntity(
      id: id,
      version: entity.version,
      weeklyGoal: entity.weeklyGoal,
      dailyGoal: entity.dailyGoal,
      diaryBlueprints: entity.diaryBlueprints,
    );
  }

  /// This method creates a new ProtocolEntity object with updated values, where certain properties
  /// are replaced with those from the provided 'model' parameter. Other properties are retained
  /// from the original ProtocolEntity object (this instance).
  ///
  /// Note:
  /// The 'id' property is not modified
  factory ProtocolEntity.fromModel({required Protocol model}) {
    return ProtocolEntity(
        id: 0,
        version: model.version,
        weeklyGoal: model.weeklyGoal,
        dailyGoal: model.dailyGoal,
        diaryBlueprints:
            model.diaryBlueprints.map((e) => jsonEncode(e.toJson())).toList());
  }
}
