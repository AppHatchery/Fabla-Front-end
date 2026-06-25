import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/services/crashlytics_service.dart';

import 'package:audio_diaries_flutter/core/database/dao/protocal_dao.dart';
import 'package:audio_diaries_flutter/core/database/dao/study_dao.dart';
import 'package:audio_diaries_flutter/core/usecases/calendar.dart';
import 'package:audio_diaries_flutter/core/usecases/diary_history.dart'
    show
        getPaginatedHistoryDiariesUseCase,
        invalidateDiaryHistoryCache,
        PaginatedDiaryResult,
        getAllHistoryDiariesUseCase;
import 'package:audio_diaries_flutter/core/usecases/homepage.dart';
import 'package:audio_diaries_flutter/core/usecases/notification_manager.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/protocol.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/protocol_entity.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';

import 'package:audio_diaries_flutter/screens/diary/domain/repository/prompt_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/summary_repository.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/study.dart';

import '../../../../core/database/dao/diary_dao.dart';
import '../../../../main.dart';
import '../../../../objectbox.g.dart';
import '../../data/diary.dart';
import '../entities/diary_entity.dart';

class DiaryRepository {
  final DiaryDAO _diaryDAO = DiaryDAO(box: Box<Diary>(objectbox.store));
  final ProtocolDAO _protocolDAO =
      ProtocolDAO(box: Box<ProtocolEntity>(objectbox.store));
  final StudyDAO _studyDAO = StudyDAO(box: Box<Study>(objectbox.store));

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

  PaginatedDiaryResult getPaginatedHistoryDiaries({
    required int page,
    required int limit,
  }) {
    return getPaginatedHistoryDiariesUseCase(page: page, limit: limit);
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

  // List<Diary> _getDiaryEntities(DateTime day) {
  //   return _diaryDAO.getDiaries(day);
  // }

  /// Retrieves a list of DiaryENtity objects from the data source based on a specified due date.
  /// This function attempts to obtain a list of DiaryEntity instances by calling the `_diaryDAO.getDailyDiary(due)` method, using the provided due date as a search criterion.
  ///
  /// Parameters:
  /// - [due]: The DateTime representing the due date of the desired diary entry.
  ///
  /// Returns:
  /// A list of Diary objects, each representing a diary entry retrieved from the data source.
  ///
  // List<Diary> _getDailyDiary(DateTime due) {
  //   return _diaryDAO.getDailyDiary(due);
  // }

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

  Future<List<DiaryModel>> getAllPending() async {
    final _summaryRepository = SummaryRepository();
    final diaries = getAllDiaries();
    final filtered =
        diaries.where((diary) => diary.status == DiaryStatus.complete).toList();

    // Get all diaries with their answers
    final copy = <DiaryModel>[];

    for (final diary in filtered) {
      final _diary = await _summaryRepository.loadSummary(diary);
      copy.add(_diary);
    }

    return copy;
  }

  /// Retrieves a list of Diary objects representing all stored diary entries.
  List<DiaryModel> getAllDiariesWithMultipleEntries() {
    // Retrieve all diaries from the database
    List<DiaryModel> unfilteredDiaries = getAllDiaries();
    final promptRepository = PromptRepository();

    // Prepare a list to store processed diaries
    final now = DateTime.now();
    final List<DiaryModel> diaries = [];

    // Process filtered diaries
    for (var diary in unfilteredDiaries) {
      final entryCount = diary.currentEntry;

      if (diary.status == DiaryStatus.missed) {
        diaries.add(diary);
        continue;
      }

      if (entryCount == 0 && diary.status != DiaryStatus.missed) {
        diaries.add(diary);
      } else {
        // Same bound logic as _generateDiaryEntryVariants: drop the phantom
        // in-progress slot when the diary is already fully submitted.
        final upperBound = (diary.status == DiaryStatus.submitted ||
                entryCount >= diary.entries)
            ? entryCount
            : entryCount + 1;

        for (var i = 0; i < upperBound; i++) {
          final newDiary = diary.copyWith(
              id: diary.id,
              studyID: diary.studyID,
              currentEntry: i,
              activeDays: diary.activeDays,
              // Be explicit: phantom in-progress slot is idle, not null
              // (null would fall back to the parent's submitted status).
              status: i < entryCount ? DiaryStatus.submitted : DiaryStatus.idle,
              submissions: diary.submissions);

          //check if diary is answered
          final prompt =
              promptRepository.load(newDiary, newDiary.prompts.first.id);

          if (prompt.answer != null ||
              (diary.status == DiaryStatus.idle && diary.due.isAfter(now))) {
            diaries.add(newDiary);
          }
        }
      }
    }

    return diaries;
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
    return getAllHistoryDiariesUseCase();
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
    final diaries = getAllDiariesWithMultipleEntries();
    return diaries
        .where((diary) =>
            DateTime(diary.due.year, diary.due.month, diary.due.day) ==
            DateTime(due.year, due.month, due.day))
        .toList();
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
    final now = DateTime.now();

    // Get all diaries that overlap with the specified time window
    final overlappingDiaries = _getOverlappingDiaries(start, end);

    // Process each diary and generate the appropriate entries
    final processedDiaries = <DiaryModel>[];
    final promptRepository = PromptRepository();

    for (final diary in overlappingDiaries) {
      final diaryEntries = _processDiaryEntries(diary, now, promptRepository);
      processedDiaries.addAll(diaryEntries);
    }

    return processedDiaries;
  }

  /// Retrieves and filters diaries that overlap with the given time window
  List<DiaryModel> _getOverlappingDiaries(DateTime start, DateTime end) {
    final allDiaryEntities = _diaryDAO.getAllDiaries();

    final overlappingEntities = allDiaryEntities
        .where((entity) => _isOverlappingWithWindow(entity, start, end))
        .toList();

    return overlappingEntities
        .map((entity) => DiaryModel.fromEntity(entity))
        .toList();
  }

  /// Checks if a diary entity overlaps with the specified time window
  bool _isOverlappingWithWindow(Diary entity, DateTime start, DateTime end) {
    return entity.start.isBefore(end) && entity.due.isAfter(start);
  }

  /// Processes a diary and returns all relevant entries based on its status and current state
  List<DiaryModel> _processDiaryEntries(
      DiaryModel diary, DateTime now, PromptRepository promptRepository) {
    // Handle missed diaries - return as-is
    if (diary.status == DiaryStatus.missed) {
      return [diary];
    }

    // Handle diaries with no entries
    if (diary.currentEntry == 0) {
      return [diary];
    }

    // Handle diaries with entries - generate entry variants
    return _generateDiaryEntryVariants(diary, now, promptRepository);
  }

  /// Generates multiple diary variants representing different entry states
  List<DiaryModel> _generateDiaryEntryVariants(
      DiaryModel diary, DateTime now, PromptRepository promptRepository) {
    final variants = <DiaryModel>[];
    final entryCount = diary.currentEntry;

    // For a fully-submitted diary there is no in-progress slot to append,
    // so the upper bound is exclusive of currentEntry. Otherwise we include
    // the "current" (in-progress) slot at index == entryCount.
    final upperBound = (diary.status == DiaryStatus.submitted ||
            entryCount >= diary.entries)
        ? entryCount
        : entryCount + 1;

    for (int entryIndex = 0; entryIndex < upperBound; entryIndex++) {
      final variant = _createDiaryVariant(diary, entryIndex, entryCount);

      if (_shouldIncludeVariant(variant, diary, now, promptRepository)) {
        variants.add(variant);
      }
    }

    return variants;
  }

  /// Creates a diary variant for a specific entry index
  DiaryModel _createDiaryVariant(
      DiaryModel originalDiary, int entryIndex, int totalEntries) {
    final isSubmittedEntry = entryIndex < totalEntries;

    return originalDiary.copyWith(
      id: originalDiary.id,
      studyID: originalDiary.studyID,
      currentEntry: entryIndex,
      // A phantom (in-progress) slot must NOT inherit a parent's submitted
      // status — that's what caused weekly counts to double for finished
      // single-entry diaries.
      status: isSubmittedEntry ? DiaryStatus.submitted : DiaryStatus.idle,
      submissions: originalDiary.submissions,
      completions: originalDiary.completions,
      activeDays: originalDiary.activeDays,
    );
  }

  /// Determines whether a diary variant should be included in the results
  bool _shouldIncludeVariant(DiaryModel variant, DiaryModel originalDiary,
      DateTime now, PromptRepository promptRepository) {
    // Load the prompt for this variant
    final prompt = promptRepository.load(variant, variant.prompts.first.id);

    // Include if the prompt has been answered
    if (prompt.answer != null) {
      return true;
    }

    // Include if the diary is idle and not yet due
    if (originalDiary.status == DiaryStatus.idle &&
        originalDiary.due.isAfter(now)) {
      return true;
    }

    return false;
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

  List<DiaryModel> getDiaries(DateTime day) {
    // Get all diaries from database
    final allDiaries = _diaryDAO.getAllDiaries();

    final availableDiaries = getDiariesUseCase(allDiaries, day);

    return availableDiaries;
  }

  /// Retrieves a list of DiaryModel objects representing every diary entry.
  /// This function fetches all diaries from the data access object (DAO),
  /// filters them to exclude those with statuses of missed or submitted,
  /// and then processes weekly diaries to create entries for each active day.
  /// For each active day in a weekly diary, it creates a new DiaryModel object
  /// with the appropriate start and due dates.
  /// Finally, it sorts the resulting list of DiaryModel objects by their start dates.
  ///
  /// Returns:
  /// A list of DiaryModel objects representing every diary entry,
  ///
  List<DiaryModel> getEveryDiary() {
    final all = _getAllDiariesEntities();

    // Remove missed and submitted diaries
    final filtered = all
        .where((diary) =>
            diary.status != DiaryStatus.missed &&
            diary.status != DiaryStatus.submitted)
        .map((e) => DiaryModel.fromEntity(e))
        .toList();

    final List<DiaryModel> diaries = [];
    final List<DiaryModel> weeklyExpansionDiaries = [];

    // For weekly diaries add diaries to each of the active days
    for (final diary in filtered) {
      if (diary.activeDays != null && diary.activeDays!.isNotEmpty) {
        final start = normalizeDate(diary.start);
        final end = normalizeDate(diary.end);
        final daysDifference = end.difference(start).inDays;

        for (int i = 0; i <= daysDifference; i++) {
          final currentDate = start.add(Duration(days: i));
          if (diary.activeDays!.contains(currentDate.weekday)) {
            // Add a copy of the diary for each active day
            final newDiary = diary.copyWith(
                id: diary.id,
                studyID: diary.studyID,
                start: DateTime(
                  currentDate.year,
                  currentDate.month,
                  currentDate.day,
                  diary.start.hour,
                  diary.start.minute,
                ),
                due: DateTime(
                  currentDate.year,
                  currentDate.month,
                  currentDate.day,
                  diary.due.hour,
                  diary.due.minute,
                ),
                submissions: diary.submissions,
                completions: diary.completions);
            weeklyExpansionDiaries.add(newDiary);
          }
        }
      } else {
        // Daily diaries
        diaries.add(diary);
      }
    }

    diaries.addAll(weeklyExpansionDiaries);
    // Sort the diaries by start date
    diaries.sort((a, b) => a.start.compareTo(b.start));

    return diaries;
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

  Study? _getStudy(int id) {
    return _studyDAO.getStudy(id);
  }

  Future<StudyModel?> getStudy(int id) async {
    final study = _getStudy(id);
    if (study != null) {
      final _study = StudyModel.fromEntity(study);
      final color = await getColorFromSharedPreferences(study.name);
      return _study.copyWith(color: color);
    }

    return null;
  }

  List<Study> _getStudies(List<int> ids) {
    List<Study> studies = [];
    for (final id in ids) {
      final study = _getStudy(id);
      if (study != null) studies.add(study);
    }

    return studies;
  }

  List<Study> getStudiesOnly(List<int> ids) {
    List<Study> studies = [];
    for (final id in ids) {
      final study = _getStudy(id);
      if (study != null) studies.add(study);
    }

    return studies;
  }

  List<Study> _getAllStudies() {
    return _studyDAO.getAllStudies();
  }

  Future<List<StudyModel>> getStudies(List<int> ids) async {
    final _studies =
        _getStudies(ids).map((e) => StudyModel.fromEntity(e)).toList();
    final updated = <StudyModel>[];
    for (final study in _studies) {
      final color = await getColorFromSharedPreferences(study.name);
      updated.add(study.copyWith(color: color));
    }
    return updated;
  }

  // For calendar use only!!!! - No color is being passed
  List<StudyModel> getAllStudies() {
    return _getAllStudies().map((e) => StudyModel.fromEntity(e)).toList();
  }

  Future<List<StudyModel>> getAllStudiesWithColor() async {
    final studies =
        _getAllStudies().map((e) => StudyModel.fromEntity(e)).toList();
    final updated = <StudyModel>[];
    for (final study in studies) {
      final color = await getColorFromSharedPreferences(study.name);
      updated.add(study.copyWith(color: color));
    }
    return updated;
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

    // Filter diaries that are only submitted
    final submittedDiaries = diaries
        .where((diary) => diary.status == DiaryStatus.submitted)
        .toList();

    return submittedDiaries.length;
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
    invalidateDiaryHistoryCache();
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
    try {
      final entity = Diary.fromModel(diary);
      _diaryDAO.updateDiary(entity);
      invalidateDiaryHistoryCache();
    } catch (e, stackTrace) {
      dev.log('Failed to update diary: $e', name: 'DiaryRepository - updateDiary');
      CrashlyticsService().recordError(e, stackTrace,
          context: {
            'Diary': diary.name.toString(),
            'DiaryID': diary.id.toString(),
            'NewStatus': diary.status.toString(),
            'CurrentEntry': diary.currentEntry.toString(),
          },
          reason:
              'Failed to persist diary state after successful upload — user may resubmit an already-uploaded diary');
      rethrow;
    }
  }

  // List<Tag> _getTags(DiaryModel diary) {
  //   List<Tag> tags = [];

  //   if (diary.status == DiaryStatus.submitted) {
  //     tags.add(const Tag(text: "Done", type: TagType.time));
  //     // } else if (diary.status == DiaryStatus.missed) {
  //     //   tags.add(const Tag(text: "Missed", type: TagType.time));
  //   } else if (diary.status == DiaryStatus.complete) {
  //     tags.add(const Tag(text: "Awaiting Submission", type: TagType.time));
  //   } else if (diary.status == DiaryStatus.ongoing) {
  //     tags.add(const Tag(text: "Ongoing", type: TagType.time));
  //   } else if (diary.status == DiaryStatus.idle) {
  //     tags.add(const Tag(text: "Ready to Start", type: TagType.time));
  //   }

  //   return tags;
  // }

  Future<int> getIndexOfLastAnsweredPrompt(DiaryModel diary) async {
    final promptRepository = PromptRepository();
    final prompts = await promptRepository.loadAll(diary);

    // Find the index of the last answered prompt
    final index = prompts.lastIndexWhere((prompt) => prompt.answer != null);

    // If no prompts are answered, return 0, else return index
    return index == -1 ? 0 : index;
  }

  bool removeAllDiaries() {
    return _diaryDAO.deleteAllDiaries();
  }

  // Removing all the diaries that start today and onwards
  Future<bool> removeDiariesFrom(DateTime now) async {
    try {
      // Get all diaries
      final all = getAllDiaries();

      dev.log("Total diaries before deletion: ${all.length}",
          name: "Diary Deletion");

      // Filter diaries that start today
      final filtered =
          all.where((diary) => !diary.start.isBefore(now)).toList();

      dev.log("Diaries to delete: ${filtered.length}", name: "Diary Deletion");

      if (filtered.isEmpty) {
        return true;
      }

      // Cancel notifications in batches to avoid blocking
      for (int i = 0; i < filtered.length; i++) {
        NotificationManager().cancelDiaryNotifications(filtered[i].id);

        // Yield to prevent blocking UI
        if (i % 10 == 0) {
          await Future.delayed(Duration.zero);
        }
      }

      // Convert to entities
      final entitiesToDelete =
          filtered.map((model) => Diary.fromModel(model)).toList();

      // Delete in the database
      final result = _diaryDAO.deleteDiaries(entitiesToDelete);

      dev.log("Deletion result: $result diaries deleted",
          name: "Diary Deletion");

      if (result > 0) {
        invalidateDiaryHistoryCache();
      }

      return result > 0;
    } catch (e) {
      dev.log("Error in removeDiariesFrom: $e", name: "Diary Deletion");
      return false;
    }
  }
}
