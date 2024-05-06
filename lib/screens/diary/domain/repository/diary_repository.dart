import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/tag.dart';

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

  /// Retrieves all history diaries grouped by date.
  ///
  /// This function retrieves all diaries from the database and filters them based on their due dates,
  /// considering only those due before the start of the next day. It then sorts the filtered diaries
  /// by due date in descending order.
  ///
  /// For each filtered diary, if it has multiple entries, it duplicates the diary for each entry,
  /// updating the current entry and status accordingly. It then sorts all diaries.
  ///
  /// After sorting, it retrieves tags for each diary and creates a map where diaries are grouped
  /// by formatted historical dates.
  ///
  /// Returns:
  /// A map where keys are formatted historical dates and values are lists of DiaryModel objects
  /// representing diaries due before the start of the next day, grouped by date.
  Map<String, List<DiaryModel>> getAllHistoryDiaries() {
    // Retrieve all diaries from the database
    List<DiaryModel> unfilteredDiaries = getAllDiaries();

    // Calculate the start of the next day
    final now = DateTime.now();
    final due = DateTime(now.year, now.month, now.day, 0, 0, 0)
        .add(const Duration(days: 1));

    // Filter diaries based on due date
    final filteredDiaries =
        unfilteredDiaries.where((diary) => diary.due.isBefore(due)).toList();

    // Sort filtered diaries by due date in descending order
    filteredDiaries.sort((a, b) => b.due.compareTo(a.due));

    // Prepare a list to store processed diaries
    final List<DiaryModel> diaries = [];

    // Process filtered diaries
    for (var diary in filteredDiaries) {
      final entryCount = diary.currentEntry;

      if (entryCount == 0) {
        diaries.add(diary);
      } else {
        for (var i = 0; i <= entryCount; i++) {
          final newDiary = diary.copyWith(
              id: diary.id,
              currentEntry: i,
              status: entryCount != i ? DiaryStatus.submitted : null);

          diaries.add(newDiary);
        }
      }
    }

    // Sort all processed diaries
    diaries.sort();

    // Retrieve tags for each diary
    for (var diary in diaries) {
      diary.tags = _getTags(diary);
    }

    // Create a map to store diaries grouped by formatted historical dates
    final Map<String, List<DiaryModel>> history = {};

    // Group diaries by formatted historical dates
    for (var i = 0; i < diaries.length; i++) {
      final diary = diaries[i];
      final date = formatHistoryDate(diary.start);

      history.update(
        date,
        (value) => value..add(diary),
        ifAbsent: () => [diary],
      );
    }

    return history;
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

  List<Tag> _getTags(DiaryModel diary) {
    List<Tag> tags = [];

    if (diary.status == DiaryStatus.submitted) {
      tags.add(const Tag(text: "Done", type: TagType.time));
    } else if (diary.status == DiaryStatus.missed) {
      tags.add(const Tag(text: "Missed", type: TagType.time));
    } else if (diary.status == DiaryStatus.complete) {
      tags.add(const Tag(text: "Awaiting Submission", type: TagType.time));
    } else if (diary.status == DiaryStatus.ongoing) {
      tags.add(const Tag(text: "Ongoing", type: TagType.time));
    } else if (diary.status == DiaryStatus.idle) {
      tags.add(const Tag(text: "Ready to Start", type: TagType.time));
    }

    return tags;
  }
}
