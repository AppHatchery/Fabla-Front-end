import '../../../../core/database/dao/diary_dao.dart';
import '../../../../main.dart';
import '../../../../objectbox.g.dart';
import '../../data/diary.dart';
import '../entities/diary_entity.dart';

class DiaryRepository {
  final DiaryDAO _diaryDAO = DiaryDAO(box: Box<DiaryEntity>(objectbox.store));

  /// A method to retrieve all DiaryEntity objects from the data source.
  /// This function retrieves a list of DiaryEntity instances by calling the `_diaryDAO.getAllDiaries()` method.
  ///
  /// Returns:
  /// A list of DiaryEntity objects representing all stored diary entries.
  ///
  List<DiaryEntity> _getAllDiariesEntities() {
    return _diaryDAO.getAllDiaries();
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
  DiaryEntity? _getDiaryEntity(DateTime due) {
    return _diaryDAO.getDiary(due);
  }

  /// Retrieves a list of Diary objects representing all stored diary entries.
  /// This function fetches a list of DiaryEntity instances from the data source using `_getAllDiariesEntities()`,
  /// and then converts each DiaryEntity into a Diary object using the `Diary.fromEntity()` factory constructor.
  ///
  /// Returns:
  /// A list of Diary objects, each representing a diary entry retrieved from the data source.
  ///
  List<Diary> getAllDiaries() {
    final diaries = _getAllDiariesEntities();
    return diaries.map((e) => Diary.fromEntity(e)).toList();
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
  Diary? getDiary(DateTime due) {
    final diary = _getDiaryEntity(due);
    if (diary != null) {
      return Diary.fromEntity(diary);
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
  Future<void> addDiaries(List<DiaryEntity> diaries) async {
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
  Future<void> updateDiary(Diary diary) async {
    final entity = DiaryEntity.fromModel(diary);
    _diaryDAO.updateDiary(entity);
  }
}
