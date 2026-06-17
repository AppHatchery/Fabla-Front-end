import 'package:audio_diaries_flutter/core/usecases/daily_goal_service.dart';
import 'package:audio_diaries_flutter/core/usecases/home_progress_tracking.dart' show getAllHomeProgressTracking;
import 'package:audio_diaries_flutter/core/usecases/homepage.dart';
import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/hub/data/submission_progress.dart' show SubmissionProgress;
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart'
    show CrashlyticsService;
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
    try {
      emit(const HomeLoading());

      final today = DateTime.now();
      final weekBoundaries = _getWeekBoundaries(today);

      // Load all necessary data in parallel for better performance
      final results = await Future.wait([
        _loadTodaysDiaries(today),
        _loadWeeklyData(weekBoundaries),
        _loadAllStudies(),
        _checkCompletionStatus(),
      ]);

      final todaysData = results[0] as TodaysData;
      final weeklyData = results[1] as WeeklyData;
      final allStudies = results[2] as List<StudyModel>;
      final isFinished = results[3] as bool;

      // Calculate goal data using the new service
      final goalService = DailyGoalService();
      final goalData = goalService.calculateDailyGoals(
          todaysData.studies, todaysData.diaries);
      
      final submissionProgress = await getAllHomeProgressTracking();

      emit(HomeLoaded(
        todaysData: todaysData,
        weeklyData: weeklyData,
        allStudies: allStudies,
        weeklyEntries: weeklyData.totalEntries,
        isFinished: isFinished,
        goalData: goalData, // Add goal data to state
        submissionProgress: submissionProgress,
      ));
    } catch (e, stackTrace) {
      debugPrint("Error loading home page: $e");
      final today = DateTime.now();
      final weekBoundaries = _getWeekBoundaries(today);
      CrashlyticsService().recordError(e, stackTrace,
          context: {
            'today': today.toIso8601String(),
            'weekBoundaries': weekBoundaries.toJson(),
          },
          reason: 'Error loading diaries in loadDiaries - HomeCubit');
      emit(const HomeError("Something went wrong"));
    }
  }

  /// Helper method to get week boundaries with shifted day logic
  WeekBoundaries _getWeekBoundaries(DateTime today) {
    // Start from Monday 4:00 AM of the current week
    final monday = DateTime(today.year, today.month, today.day, 4, 0, 0)
        .subtract(Duration(days: today.weekday - 1));

    // End on Sunday 3:59 AM of the current week
    final sunday = DateTime(monday.year, monday.month, monday.day, 3, 59, 0)
        .add(const Duration(days: 6));

    return WeekBoundaries(start: monday, end: sunday);
  }

  /// Load today's diaries and their studies
  Future<TodaysData> _loadTodaysDiaries(DateTime today) async {
    final diaries = repository.getDiaries(today);

    if (diaries.isEmpty) {
      return TodaysData(diaries: [], studies: []);
    }

    final sortedDiaries = prioritySort(diaries);

    // Get unique study IDs and load studies
    final studyIds = diaries.map((e) => e.studyID).toSet().toList();
    final studies = await repository.getStudies(studyIds);

    return TodaysData(diaries: sortedDiaries, studies: studies);
  }

  /// Load weekly data (diaries and entry count)
  Future<WeeklyData> _loadWeeklyData(WeekBoundaries boundaries) async {
    final weekDiaries =
        repository.getRangeDiaries(boundaries.start, boundaries.end);
    final totalEntries = repository.getTotalEntries(
        boundaries.start.subtract(const Duration(days: 1)),
        boundaries.end.add(const Duration(days: 1)));

    // Get unique study IDs and load studies
    final studyIds = weekDiaries.map((e) => e.studyID).toSet().toList();
    final studies = await repository.getStudies(studyIds);

    return WeeklyData(
        diaries: weekDiaries, studies: studies, totalEntries: totalEntries);
  }

  /// Load all studies
  Future<List<StudyModel>> _loadAllStudies() async {
    return await repository.getAllStudiesWithColor();
  }

  /// Check if user has completed all studies
  Future<bool> _checkCompletionStatus() async {
    return await noMoreDiaries();
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

/// Data classes for better organization
class TodaysData {
  final List<DiaryModel> diaries;
  final List<StudyModel> studies;

  TodaysData({required this.diaries, required this.studies});
}

class WeeklyData {
  final List<StudyModel> studies;
  final List<DiaryModel> diaries;
  final int totalEntries;

  WeeklyData(
      {required this.diaries,
      required this.studies,
      required this.totalEntries});
}

class WeekBoundaries {
  final DateTime start;
  final DateTime end;

  WeekBoundaries({required this.start, required this.end});

  Map<String, String> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };
  }
}
