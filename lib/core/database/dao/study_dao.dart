import 'package:audio_diaries_flutter/screens/home/domain/entities/study.dart';
import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';

class StudyDAO {
  final Box<Study> box;

  StudyDAO({required this.box});

  /// Retrieves a study with the specified ID from the database.
  ///
  /// This method first filters all studies to find those matching the given studyId,
  /// then returns the first matching study if found, or null if no study exists.
  ///
  /// The implementation uses a two-step process to safely handle the case where
  /// no study is found, avoiding the "Bad state: No element" exception that would
  /// occur with a direct .first call on an empty iterable.
  ///
  /// Parameters:
  /// - [id]: The studyId to search for
  ///
  /// Returns:
  /// - A Study object if found, null otherwise
  ///
  /// Example:
  /// ```dart
  /// final study = studyDAO.getStudy(123);
  /// if (study != null) {
  ///   // Use the study
  /// } else {
  ///   // Handle case where study doesn't exist
  /// }
  /// ```
  ///
  /// Note: This implementation was updated to handle the case where no study is found
  /// by returning null instead of throwing a "Bad state: No element" exception. This
  /// matches the expected behavior in tests and provides a better way to handle
  /// missing studies.
  /// original implementation:
  /// Study? getStudy(int id) {
  /// return box.getAll().where((element) => element.studyId == id).first;
  /// }
  Study? getStudy(int id) {
    final studies = box.getAll().where((element) => element.studyId == id);
    return studies.isEmpty ? null : studies.first;
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
