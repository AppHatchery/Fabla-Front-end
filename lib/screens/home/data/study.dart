import 'dart:convert';

import 'package:audio_diaries_flutter/screens/home/data/incentive.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/study.dart';

class StudyModel {
  final int id;
  final int studyId;
  final String experimentCode;
  final Goal goals;
  final Incentive incentive;

  StudyModel({
    required this.id,
    required this.studyId,
    required this.experimentCode,
    required this.goals,
    required this.incentive,
  });

  factory StudyModel.fromJson(Map<String, dynamic> json, String loginCode) {
    return StudyModel(
      id: 0,
      experimentCode: loginCode,
      studyId: json['id'],
      goals: Goal.fromJson(json['goal']),
      incentive: Incentive.fromJson(json['incentive']),
    );
  }

  factory StudyModel.fromEntity(Study entity) {
    return StudyModel(
        id: entity.id,
        studyId: entity.studyId,
        experimentCode: entity.experimentCode,
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
