import 'dart:convert';

import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Study {
  @Id()
  int id;
  int studyId;
  String goals;
  String incentive;

  Study({
    required this.id,
    required this.studyId,
    required this.goals,
    required this.incentive,
  });

  factory Study.fromModel(StudyModel model) {
    return Study(
        id: model.id,
        studyId: model.studyId,
        goals: json.encode(model.goals.toJson()),
        incentive: json.encode(model.incentive.toJson()));
  }
}
