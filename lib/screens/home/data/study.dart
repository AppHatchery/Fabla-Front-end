import 'dart:convert';

import 'package:audio_diaries_flutter/screens/home/data/incentive.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/study.dart';
import 'package:flutter/material.dart';

class StudyModel {
  final int id;
  final int studyId;
  final String name;
  final String experimentCode;
  final Color? color;
  final Goal goals;
  final Incentive incentive;

  StudyModel({
    required this.id,
    required this.studyId,
    required this.name,
    required this.experimentCode,
    required this.color,
    required this.goals,
    required this.incentive,
  });

  factory StudyModel.fromJson(Map<String, dynamic> json, String loginCode) {
    return StudyModel(
      id: 0,
      experimentCode: loginCode,
      studyId: json['id'],
      name: json['name'],
      color: null,
      goals: Goal.fromJson(json['goal']),
      incentive: Incentive.fromJson(json['incentive']),
    );
  }

  factory StudyModel.fromEntity(Study entity) {
    return StudyModel(
        id: entity.id,
        studyId: entity.studyId,
        name: entity.name,
        experimentCode: entity.experimentCode,
        color: null,
        goals: Goal.fromJson(jsonDecode(entity.goals)),
        incentive: Incentive.fromJson(jsonDecode(entity.incentive)));
  }

  StudyModel copyWith({
    int? id,
    int? studyId,
    String? name,
    String? experimentCode,
    Color? color,
    Goal? goals,
    Incentive? incentive,
  }) {
    return StudyModel(
      id: id ?? this.id,
      studyId: studyId ?? this.studyId,
      name: name ?? this.name,
      experimentCode: experimentCode ?? this.experimentCode,
      color: color ?? this.color,
      goals: goals ?? this.goals,
      incentive: incentive ?? this.incentive,
    );
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
