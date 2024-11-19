import 'package:audio_diaries_flutter/screens/home/domain/entities/experiment.dart';
import 'package:objectbox/objectbox.dart';

class ExperimentDAO {
  final Box<Experiment> box;

  ExperimentDAO({required this.box});

  Experiment? getExperiment() {
    return box.getAll().first;
  }

  void addExperiment(Experiment experiment) {
    box.put(experiment);
  }

  void replaceExperiment(Experiment experiment) {
    deleteExperiment();
    addExperiment(experiment);
  }

  void deleteExperiment() {
    box.removeAll();
  }
}
