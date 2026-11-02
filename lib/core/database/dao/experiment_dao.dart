import 'package:audio_diaries_flutter/screens/home/domain/entities/experiment.dart';
import 'package:objectbox/objectbox.dart';

class ExperimentDAO {
  final Box<Experiment> box;

  ExperimentDAO({required this.box});

  Experiment? getExperiment() {
    final experiments = box.getAll();
    return experiments.isEmpty ? null : experiments.first;
  }

  void addExperiment(Experiment experiment) {
    box.put(experiment);
  }

  void replaceExperiment(Experiment experiment) {
    deleteExperiment();
    addExperiment(experiment);
  }

  /// Updates only the owner email of the stored experiment, keeping its id
  /// and every other field intact. Does nothing if no experiment is stored.
  void updateOwnerEmail(String ownerEmail) {
    final experiment = getExperiment();
    if (experiment == null) return;
    experiment.ownerEmail = ownerEmail;
    box.put(experiment);
  }

  void deleteExperiment() {
    box.removeAll();
  }
}
