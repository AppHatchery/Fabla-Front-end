import 'dart:convert';

import 'package:audio_diaries_flutter/screens/home/data/incentive.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/study.dart';

class StudyModel {
  final int id;
  final int studyId;
  final Goal goals;
  final Incentive incentive;

  StudyModel({
    required this.id,
    required this.studyId,
    required this.goals,
    required this.incentive,
  });

  factory StudyModel.fromJson(Map<String, dynamic> json) {
    return StudyModel(
      id: 0,
      studyId: json['id'],
      goals: Goal.fromJson(json['goals']),
      incentive: Incentive.fromJson(json['incentive']),
    );
  }

  factory StudyModel.fromEntity(Study entity) {
    return StudyModel(
        id: entity.id,
        studyId: entity.studyId,
        goals: Goal.fromJson(jsonDecode(entity.goals)),
        incentive: Incentive.fromJson(jsonDecode(entity.incentive)));
  }
}

class Goal {
  final int daily;
  final int weekly;

  Goal({
    required this.daily,
    required this.weekly,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      daily: json['daily'],
      weekly: json['weekly'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily': daily,
      'weekly': weekly,
    };
  }
}
