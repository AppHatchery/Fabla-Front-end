import 'package:audio_diaries_flutter/screens/home/domain/entities/experiment.dart';

class ExperimentModel {
  int id;
  final String login;
  final String researcher;
  final String organization;
  final String name;
  final String duration;
  final String description;

  ExperimentModel(
      {required this.id,
      required this.login,
      required this.researcher,
      required this.organization,
      required this.name,
      required this.duration,
      required this.description});

  factory ExperimentModel.fromJson(Map<String, dynamic> json) {
    return ExperimentModel(
      id: 0,
      login: json['login_code'] ?? '',
      researcher: json['researcher'] ?? '',
      organization: json['organisation'] ?? '',
      name: json['name'] ?? '',
      duration: json['duration'] ?? '',
      description: json['description'] ?? '',
    );
  }

  factory ExperimentModel.fromEntity(Experiment entity) {
    return ExperimentModel(
      id: entity.id,
      login: entity.login,
      researcher: entity.researcher,
      organization: entity.organization,
      name: entity.name,
      duration: entity.duration,
      description: entity.description,
    );
  }
}
