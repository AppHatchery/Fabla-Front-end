import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Experiment {
  @Id()
  int id;
  String login;
  String researcher;
  String organization;
  String name;
  String duration;
  String description;

  Experiment(
      {required this.id,
      required this.login,
      required this.researcher,
      required this.organization,
      required this.name,
      required this.duration,
      required this.description});

  factory Experiment.fromModel(ExperimentModel model) {
    return Experiment(
      id: model.id,
      login: model.login,
      researcher: model.researcher,
      organization: model.organization,
      name: model.name,
      duration: model.duration,
      description: model.description,
    );
  }
}
