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
  /// and every other field intact.
  ///
  /// The write is skipped unless the stored experiment still has [login]
  /// (case-insensitive), so a slow request for one study can never write onto
  /// a different study joined in the meantime. Returns whether it wrote.
  bool updateOwnerEmail(String login, String ownerEmail) {
    final experiment = getExperiment();
    if (experiment == null ||
        experiment.login.toLowerCase() != login.toLowerCase()) {
      return false;
    }
    experiment.ownerEmail = ownerEmail;
    box.put(experiment);
    return true;
  }

  void deleteExperiment() {
    box.removeAll();
  }
}
