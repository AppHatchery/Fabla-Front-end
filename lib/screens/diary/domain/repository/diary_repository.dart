import 'package:audio_diaries_flutter/core/database/dao/protocal_dao.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/protocol.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/protocol_entity.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';

import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/tag.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/prompt_repository.dart';

import '../../../../core/database/dao/diary_dao.dart';
import '../../../../main.dart';
import '../../../../objectbox.g.dart';
import '../../data/diary.dart';
import '../entities/diary_entity.dart';

class DiaryRepository {
  final DiaryDAO _diaryDAO = DiaryDAO(box: Box<Diary>(objectbox.store));
  final ProtocolDAO _protocolDAO =
      ProtocolDAO(box: Box<ProtocolEntity>(objectbox.store));

  /// A method to retrieve all DiaryEntity objects from the data source.
  /// This function retrieves a list of DiaryEntity instances by calling the `_diaryDAO.getAllDiaries()` method.
  ///
  /// Returns:
  /// A list of DiaryEntity objects representing all stored diary entries.
  ///
  List<Diary> _getAllDiariesEntities() {
    final diaries = _diaryDAO.getAllDiaries();
    final now = DateTime.now();
    final due = DateTime(now.year, now.month, now.day, 23, 59, 0);
    final unSubmittedDiaries = diaries
        .where((diary) => diary.due.isBefore(due))
        .where((element) => element.status != DiaryStatus.submitted)
        .toList();

    if (unSubmittedDiaries.isNotEmpty) {
      for (final diary in unSubmittedDiaries) {
        if (now.isAfter(due) &&
            diary.status != DiaryStatus.complete &&
            diary.currentEntry == 0) {
          diary.status = DiaryStatus.missed;
        } else if (now.isAfter(due) && diary.currentEntry > 0) {
          diary.status = DiaryStatus.submitted;
        }
      }

      _diaryDAO.updateDiaries(unSubmittedDiaries);
      return _diaryDAO.getAllDiaries();
    }
    return diaries;
  }


  

  // List<Diary> _getAllHomeDiariesEntities() {
  //   final diaries = _diaryDAO.getAllDiaries();
  //   final now = DateTime.now();

  //   // Iterate over all diaries to update their statuses based on due dates.
  //   for (final diary in diaries) {
  //     if (now.isAfter(diary.due)) {
  //       // If the diary is past due
  //       if (diary.status != DiaryStatus.complete && diary.currentEntry == 0) {
  //         diary.status = DiaryStatus.missed;
  //       } else if (diary.currentEntry > 0) {
  //         diary.status = DiaryStatus.submitted;
  //       }
  //     }
  //     // No else block needed; diaries not past due retain their current status.
  //   }

  //   // Update all diaries in the database after potentially updating their statuses.
  //   _diaryDAO.updateDiaries(diaries);

  //   // Filter out diaries marked as missed from the list to be returned.
  //   final filteredDiaries =
  //       diaries.where((diary) => diary.status != DiaryStatus.missed).toList();

  //   return filteredDiaries;
  // }

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

  List<Diary> _getDiaryEntities(DateTime day) {
    return _diaryDAO.getDiaries(day);
  }

  /// Retrieves a list of DiaryENtity objects from the data source based on a specified due date.
  /// This function attempts to obtain a list of DiaryEntity instances by calling the `_diaryDAO.getDailyDiary(due)` method, using the provided due date as a search criterion.
  ///
  /// Parameters:
  /// - [due]: The DateTime representing the due date of the desired diary entry.
  ///
  /// Returns:
  /// A list of Diary objects, each representing a diary entry retrieved from the data source.
  ///
  List<Diary> _getDailyDiary(DateTime due) {
    return _diaryDAO.getDailyDiary(due);
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

  ProtocolEntity? _getProtocolEntity() {
    return _protocolDAO.getProtocol();
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
    final promptRepository = PromptRepository();

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

      if (diary.status == DiaryStatus.missed) {
        continue;
      }

      if (entryCount == 0) {
        diaries.add(diary);
      } else {
        for (var i = 0; i <= entryCount; i++) {
          final newDiary = diary.copyWith(
              id: diary.id,
              currentEntry: i,
              status: entryCount != i ? DiaryStatus.submitted : null);

          //check if diary is answered
          final prompt =
              promptRepository.load(newDiary, newDiary.prompts.first.id);

          if (prompt.answer != null || diary.status == DiaryStatus.idle) {
            diaries.add(newDiary);
          }
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

  /// Counts the number of days with submitted diary entries `ActiveDays` of the user.
  ///
  /// This function retrieves all diaries from the database,
  /// It processes eached retrieved diary to check if it has any entry with status of submitted
  /// If any entry in a diary is submitted, the due date is added to a set of submitted days ensuring that each day is counted only once
  ///
  /// For each  diary, if it has multiple entries, it duplicates the diary for each entry,
  /// updating the current entry and status accordingly. It checks if the entry has the status of submitted.
  ///
  /// Returns:
  /// An integer representing the number of unique days with at least one submitted diary entry.
  int countSubmittedDays() {
    List<DiaryModel> diaries = getAllDiaries();
    // Initialize a set to keep track of days with submitted entries
    final Set<DateTime> submittedDays = {};
    for (var diary in diaries) {
      if (diary.currentEntry > 0) {
        submittedDays.add(diary.due);
      }
    }
    return submittedDays.length;
  }

  /// Retrieves a list of Diary objects for a specified due date.
  /// This function fetches a list of DiaryEntity instances from the data source using `_getDailyDiary(due)`,
  /// and then converts each DiaryEntity into a Diary object using the `Diary.fromEntity()` factory constructor.
  ///
  /// Returns:
  /// A list of Diary objects, each representing a diary entry retrieved from the data source matching the criteria.
  ///
  List<DiaryModel> getDailyDiaries(DateTime due) {
    final diaries = _getDailyDiary(due);
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

  // List<DiaryModel> fetchActiveDiaries(DateTime day, DateTime currentTime) {
  //   return getDiaries(day, currentTime);
  // }

  List<DiaryModel> getDiaries(DateTime day) {
    final diaries = _getDiaryEntities(day)
        .where((diary) =>
                DateTime(diary.start.year, diary.start.month, diary.start.day)
                    .isAtSameMomentAs(DateTime(day.year, day.month, day.day))
            //     &&
            // currentTime.isAfter(diary.start) &&
            // currentTime.isBefore(diary.end)
            )
        .toList();
    return diaries.map((e) => DiaryModel.fromEntity(e)).toList();
  }

  // retrieves the protocol from the protocol entity
  // This function attempts to obtain a ProtocolEntity instance using the `_getProtocolEntity()` method,
  // and if a matching ProtocolEntity is found, it is transformed into a Protocol object using the `Protocol.fromEntity()` factory constructor.
  // returns:
  // A Protocol object representing the protocol entity, if found, or null if no matching entity is found in the data source.
  Protocol? getProtocol() {
    final protocol = _getProtocolEntity();
    if (protocol != null) {
      return Protocol.fromEntity(protocol);
    }
    return null;
  }

// get ema diaries
  List<DiaryModel> getEMADiaries() {
    final allDiaries = getAllDiaries();
    return allDiaries.where((diary) => diary.type == DiaryTypes.ema).toList();
  }

//get daily diaries
  List<DiaryModel> getDiariesDaily() {
    final allDiaries = getAllDiaries();
    return allDiaries.where((diary) => diary.type == DiaryTypes.daily).toList();
  }

  // get survey diaries
  List<DiaryModel> getSurveyDiaries() {
    final allDiaries = getAllDiaries();
    return allDiaries
        .where((diary) => diary.type == DiaryTypes.survey)
        .toList();
  }

  /// Retrieves the total number of diary entries within a specified date range.
  /// This function fetches all diaries filters them based on their start dates falling within the specified date range.
  /// It then calculates the total number of entries across all filtered diaries and returns the sum.
  /// Parameters:
  /// - [start]: The start date of the range.
  /// - [end]: The end date of the range.
  ///
  /// Returns:
  /// An integer representing the total number of diary entries within the specified date range.
  int getTotalEntries(DateTime start, DateTime end) {
    final diaries = getRangeDiaries(start, end);
    return diaries.fold(
        0, (previousValue, element) => previousValue + element.currentEntry);
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
