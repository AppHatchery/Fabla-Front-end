import 'package:audio_diaries_flutter/core/usecases/homepage.dart';
import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../diary/data/diary.dart';
import '../../../../diary/domain/repository/diary_repository.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  // Modified to support dependency injection for better testability
  // Added constructor parameters for diary repository and setup repository
  // Default values maintain backward compatibility
  final DiaryRepository repository;
  final SetupRepository setupRepository;

  // Constructor with optional dependency injection
  // If not provided, uses default implementations for production use
  HomeCubit({
    DiaryRepository? diaryRepository,
    SetupRepository? setupRepository,
  })  : repository = diaryRepository ?? DiaryRepository(),
        setupRepository = setupRepository ?? SetupRepository(),
        super(const HomeInitial());

  /// Asynchronous method to load and organize Diary objects for display on the home screen.
  /// This function initiates the loading process of Diary objects and their organization for display on the home screen.
  /// It emits a `HomeLoading` state to signal the start of the loading process. Then, it fetches the Diary for the current day
  /// using `repository.getDiary(today)` and organizes the Diaries into different lists based on their status.
  /// The loaded Diaries are sorted by their status, and a `HomeLoaded` state is emitted with the organized Diaries.
  ///
  /// Note:
  /// Any exceptions that occur during the loading process are caught, and a `HomeError` state is emitted with an error message.
  ///
  /// Returns:
  /// A Future indicating that the operation may be asynchronous and requires awaiting.
  ///
  Future<void> loadDiaries() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day, 4, 0, 0);
    // final due = DateTime(today.year, today.month, today.day, 3, 59, 59);

    final monday = DateTime(today.year, today.month, today.day, 4, 0, 0)
        .subtract(Duration(days: today.weekday - 1));
    final sunday = DateTime(monday.year, monday.month, monday.day, 3, 59, 0)
        .add(const Duration(days: 6));

    try {
      emit(const HomeLoading());
      // Updated to use injected repository instance
      final diaries = repository.getDiaries(start);
      // Updated to use injected repository instance
      final entries = repository.getTotalEntries(
          monday.subtract(const Duration(days: 1)),
          sunday.add(const Duration(days: 1)));
      // Updated to use injected repository instance
      final weekDiaries = repository.getRangeDiaries(monday, sunday);
      final completedStudy = await noMoreDiaries();

      final ids = weekDiaries.map((e) => e.studyID).toSet().toList();
      // Updated to use injected repository instance
      final studies = await repository.getStudies(ids);
      // Updated to use injected repository instance
      final allStudies = await repository.getAllStudiesWithColor();

      final updated = diaries
          .map((diary) => diary.copyWith(
              id: diary.id,
              studyID: diary.studyID,
              tags: null,
              activeDays: diary.activeDays))
          .toList();

      final sortedDiaries = prioritySort(updated);
      emit(HomeLoaded(
        sortedDiaries,
        weekDiaries,
        diaries.isNotEmpty,
        studies,
        allStudies,
        entries,
        completedStudy,
      ));
    } catch (e) {
      debugPrint("Error loading home page: $e");
      emit(const HomeError("Something went wrong"));
    }
  }

  Future<String> getParticipantName() async =>
      // Updated to use injected setupRepository instance
      setupRepository.getParticipant()!.name;

  Future<String> getParticipantCode() async =>
      // Updated to use injected setupRepository instance
      setupRepository.getParticipant()!.studyCode;

  ExperimentModel getExperiment() =>
      // Updated to use injected setupRepository instance
      setupRepository.getExperiment();

  Future<List<DiaryModel>> getAllDiaries() async =>
      // Updated to use injected repository instance
      repository.getAllDiaries();

  List<DiaryModel> getAllDiariesThisWeek() {
    final today = DateTime.now().weekday;

    int daysUntilMonday = today == 1 ? 0 : 7 - today;
    final monday = DateTime(
        DateTime.now().add(Duration(days: -daysUntilMonday)).year,
        DateTime.now().add(Duration(days: -daysUntilMonday)).month,
        DateTime.now().add(Duration(days: -daysUntilMonday)).day);
    final sunday = monday.add(const Duration(days: 6));

    // Updated to use injected repository instance
    final diaries = repository.getAllDiaries();
    final thisWeek = diaries
        .where((element) =>
            element.due.isAfter(monday.subtract(const Duration(days: 1))) &&
            element.due.isBefore(sunday))
        .toList();
    thisWeek.sort((a, b) => a.due.compareTo(b.due));
    return thisWeek;
  }

  //Retrieving diaries due on a specific date for the calendar widget
  List<DiaryModel> getAllDiariesThisDay(DateTime date) {
    // Updated to use injected repository instance
    return repository.getDailyDiaries(date);
  }

  // Checking if there are no more diaries for study
  // ! Potential problem: Premature showing of 'End of Journey' if study is ongoing and updatable
  Future<bool> noMoreDiaries() async {
    final today = DateTime.now();
    final diaries = await getAllDiaries();
    final last = diaries.where((diary) => diary.due.isAfter(today)).toList();
    return last.isEmpty;
  }
}
