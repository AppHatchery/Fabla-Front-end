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

  /// Overwrites the stored experiment with [updated], keeping its id.
  ///
  /// The write is skipped unless the stored experiment still has [login]
  /// (case-insensitive), so a slow request for one study can never write onto
  /// a different study joined in the meantime. Uses a single `put`, so there is
  /// no window where the experiment is missing. Returns whether it wrote.
  bool updateExperiment(String login, Experiment updated) {
    final stored = getExperiment();
    if (stored == null || stored.login.toLowerCase() != login.toLowerCase()) {
      return false;
    }
    updated.id = stored.id;
    box.put(updated);
    return true;
  }

  void deleteExperiment() {
    box.removeAll();
  }
}
