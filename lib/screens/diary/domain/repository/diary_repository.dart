import 'package:audio_diaries_flutter/core/utils/statuses.dart';

import '../../../../core/database/dao/diary_dao.dart';
import '../../../../main.dart';
import '../../../../objectbox.g.dart';
import '../../data/diary.dart';
import '../entities/diary_entity.dart';

class DiaryRepository {
  final DiaryDAO _diaryDAO = DiaryDAO(box: Box<Diary>(objectbox.store));

  /// A method to retrieve all DiaryEntity objects from the data source.
  /// This function retrieves a list of DiaryEntity instances by calling the `_diaryDAO.getAllDiaries()` method.
  ///
  /// Returns:
  /// A list of DiaryEntity objects representing all stored diary entries.
  ///
  List<Diary> _getAllDiariesEntities() {
    final diaries = _diaryDAO.getAllDiaries();
    final now = DateTime.now();
    final due = DateTime(now.year, now.month, now.day, 4, 0, 0);
    final unSubmittedDiaries = diaries
        .where((diary) => diary.due.isBefore(due))
        .where((element) => element.status != DiaryStatus.submitted)
        .toList();

    if (unSubmittedDiaries.isNotEmpty) {
      for (final diary in unSubmittedDiaries) {
        if (now.isAfter(due) && diary.status != DiaryStatus.complete) {
          diary.status = DiaryStatus.missed;
        }
      }

      _diaryDAO.updateDiaries(unSubmittedDiaries);
      return _diaryDAO.getAllDiaries();
    }
    return diaries;
  }

  /// Retrieves a DiaryEntity object from the data source based on a specified due date.
  /// This function attempts to obtain a DiaryEntity instance by calling the `_diaryDAO.getDiary(due)` method, using the provided due date as a search criterion.
  ///
  /// Parameters:
  /// - [due]: The DateTime representing the due date of the desired diary entry.
  ///
  /// Returns:
  /// A DiaryEntity object representing the diary entry with the specified due date, if found,
  /// or null if no matching entry is found in the data source.
  ///
  Diary? _getDiaryEntity(DateTime start, DateTime due) {
    return _diaryDAO.getDiary(start, due);
  }

  /// Retrieves a diary entity from the data access object (DAO) by its ID.
  ///
  /// This function delegates the retrieval of a diary entity from the DAO based on the provided ID.
  /// It returns the diary entity if found, otherwise returns null.
  ///
  /// Parameters:
  /// - [id]: The ID of the diary entity to retrieve.
  ///
  /// Returns:
  /// The Diary entity with the specified ID if found, otherwise null.
  Diary? _getDiaryEntityByID(int id) {
    // Delegate the retrieval of the diary entity to the DAO
    return _diaryDAO.getDiaryByID(id);
  }

  /// Retrieves a list of Diary objects representing all stored diary entries.
  /// This function fetches a list of DiaryEntity instances from the data source using `_getAllDiariesEntities()`,
  /// and then converts each DiaryEntity into a Diary object using the `Diary.fromEntity()` factory constructor.
  ///
  /// Returns:
  /// A list of Diary objects, each representing a diary entry retrieved from the data source.
  ///
  List<DiaryModel> getAllDiaries() {
    final diaries = _getAllDiariesEntities();
    return diaries.map((e) => DiaryModel.fromEntity(e)).toList();
  }

  /// Retrieves a list of diary models within a specified date range.
  ///
  /// This function retrieves all diaries from the data access object (DAO) and filters them
  /// based on their start dates falling within the specified date range. It then maps the
  /// filtered diaries to DiaryModel objects and returns them.
  ///
  /// Parameters:
  /// - [start]: The start date of the range.
  /// - [end]: The end date of the range.
  ///
  /// Returns:
  /// A list of DiaryModel objects representing diaries within the specified date range.
  List<DiaryModel> getRangeDiaries(DateTime start, DateTime end) {
    // Retrieve all diaries from the DAO
    final diaries = _diaryDAO.getAllDiaries();

    // Filter diaries based on their start dates falling within the specified range
    final filtered = diaries.where((element) {
      return element.start.isAfter(start) && element.start.isBefore(end);
    }).toList();

    // Map filtered diaries to DiaryModel objects and return them
    return filtered.map((e) => DiaryModel.fromEntity(e)).toList();
  }

  /// Retrieves a diary model by its ID.
  ///
  /// This function retrieves a diary entity by its ID and converts it into a DiaryModel object.
  ///
  /// Parameters:
  /// - [id]: The ID of the diary to retrieve.
  ///
  /// Returns:
  /// The DiaryModel object with the specified ID if found, otherwise null.
  DiaryModel? getDiaryByID(int id) {
    // Retrieve the diary entity by its ID
    final diary = _getDiaryEntityByID(id);
    // Convert the diary entity into a DiaryModel object
    if (diary != null) {
      return DiaryModel.fromEntity(diary);
    }
    // Return null if the diary entity is not found
    return null;
  }

  /// Retrieves a Diary object from the data source based on a specified due date.
  /// This function attempts to obtain a DiaryEntity instance using the `_getDiaryEntity(due)` method,
  /// and if a matching DiaryEntity is found, it is transformed into a Diary object using the `Diary.fromEntity()` factory constructor.
  ///
  /// Parameters:
  /// - [due]: The DateTime representing the due date of the desired diary entry.
  ///
  /// Returns:
  /// A Diary object representing the diary entry with the specified due date, if found,
  /// or null if no matching entry is found in the data source.
  ///
  DiaryModel? getDiary(DateTime start, DateTime due) {
    final diary = _getDiaryEntity(start, due);
    if (diary != null) {
      return DiaryModel.fromEntity(diary);
    }
    return null;
  }

  /// Asynchronous method to add a list of DiaryEntity objects to the data source.
  /// This function adds a provided list of DiaryEntity instances to the data source by calling the `_diaryDAO.addDiaries(diaries)` method.
  ///
  /// Parameters:
  /// - [diaries]: A list of DiaryEntity objects representing diary entries to be added to the data source.
  ///
  /// Returns:
  /// A Future indicating that the operation may be asynchronous and requires awaiting.
  ///
  Future<void> addDiaries(List<Diary> diaries) async {
    _diaryDAO.addDiaries(diaries);
  }

  /// Asynchronous method to update a Diary object in the data source.
  /// This function converts a provided Diary object into a corresponding DiaryEntity using `DiaryEntity.fromModel()`,
  /// and then updates the corresponding entry in the data source by calling `_diaryDAO.updateDiary(entity)`.
  ///
  /// Parameters:
  /// - [diary]: The Diary object containing updated data to be persisted in the data source.
  ///
  /// Returns:
  /// A Future indicating that the operation may be asynchronous and requires awaiting.
  ///
  Future<void> updateDiary(DiaryModel diary) async {
    final entity = Diary.fromModel(diary);
    _diaryDAO.updateDiary(entity);
  }
}
