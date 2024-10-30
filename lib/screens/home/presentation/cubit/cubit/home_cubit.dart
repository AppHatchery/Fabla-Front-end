import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../../core/utils/statuses.dart';
import '../../../../../core/utils/types.dart';
import '../../../../diary/data/diary.dart';
import '../../../../diary/data/tag.dart';
import '../../../../diary/domain/repository/diary_repository.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeInitial());
  DiaryRepository repository = DiaryRepository();
  final SetupRepository setupRepository = SetupRepository();

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
    final start = DateTime(today.year, today.month, today.day, 0, 0, 0);
    // final due = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    try {
      emit(const HomeLoading());
      final diaries = repository.getDiaries(start);
      final entries = repository.getTotalEntries(
          monday.subtract(const Duration(days: 1)),
          sunday.add(const Duration(days: 1)));
      final weekDiaries = repository.getRangeDiaries(monday, sunday);

      final ids = weekDiaries.map((e) => e.studyID).toSet().toList();
      final studies = await repository.getStudies(ids);

      final updated = diaries
          .map((diary) =>
              diary.copyWith(id: diary.id, studyID: diary.studyID, tags: null))
          .toList()
          .where((element) =>
              element.due.isAfter(DateTime.now()) &&
              (element.status != DiaryStatus.submitted &&
                  element.status != DiaryStatus.missed))
          .toList();

      updated.sort((a, b) => b.compareTo(a));
      emit(HomeLoaded(
          updated, weekDiaries, diaries.isNotEmpty, studies, entries));
    } catch (e) {
      debugPrint("Error loading home page: $e");
      emit(const HomeError("Something went wrong"));
    }
  }

  Future<String> getParticipantName() async =>
      setupRepository.getParticipant()!.name;

  Future<List<DiaryModel>> getAllDiaries() async => repository.getAllDiaries();

  List<DiaryModel> getAllDiariesThisWeek() {
    final today = DateTime.now().weekday;

    int daysUntilMonday = today == 1 ? 0 : 7 - today;
    final monday = DateTime(
        DateTime.now().add(Duration(days: -daysUntilMonday)).year,
        DateTime.now().add(Duration(days: -daysUntilMonday)).month,
        DateTime.now().add(Duration(days: -daysUntilMonday)).day);
    final sunday = monday.add(const Duration(days: 6));

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
    return repository.getDailyDiaries(date);
  }
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
    tags.addAll([
      const Tag(text: "13 Questions", type: TagType.questions),
      const Tag(text: "12 Minutes", type: TagType.time)
    ]);
  }

  return tags;
}
