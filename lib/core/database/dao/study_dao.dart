import 'package:audio_diaries_flutter/screens/home/domain/entities/study.dart';
import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';

class StudyDAO {
  final Box<Study> box;

  StudyDAO({required this.box});

  Study? getStudy(int id) {
    return box.getAll().where((element) => element.studyId == id).firstOrNull;
  }

  List<Study> getStudies() {
    return box.getAll().where((element) => false).toList();
  }

  List<Study> getAllStudies() {
    return box.getAll();
  }

  int? addStudy(Study study) {
    try {
      return box.put(study);
    } catch (e) {
      debugPrint("Error add study in database: $e");
      return null;
    }
  }

  List<int> addStudies(List<Study> studies) {
    return box.putMany(studies);
  }

  /// Inserts or updates studies, matching existing rows by [Study.studyId].
  /// Studies already stored but missing from [studies] are kept, so older
  /// diaries that reference them can still resolve their study.
  List<int> upsertStudies(List<Study> studies) {
    final existing = {for (final s in box.getAll()) s.studyId: s.id};
    for (final study in studies) {
      study.id = existing[study.studyId] ?? 0;
    }
    return box.putMany(studies);
  }

  bool deleteStudy(int id) {
    try {
      return box.remove(id);
    } catch (e) {
      debugPrint("Error deleting study: $e");
      return false;
    }
  }

  /// Deletes all studies from the database.
  /// This function removes all study entries from the underlying storage box.
  ///
  /// Returns:
  /// True if all studies were successfully deleted, false otherwise.
  bool deleteAllStudies() {
    try {
      box.removeAll();
      return true;
    } catch (e) {
      debugPrint("Error deleting all studies: $e");
      return false;
    }
  }
}
