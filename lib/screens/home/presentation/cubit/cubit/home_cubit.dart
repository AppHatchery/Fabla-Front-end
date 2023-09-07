import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/utils/statuses.dart';
import '../../../../diary/data/diary.dart';
import '../../../../diary/domain/repository/diary_repository.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeInitial());
  DiaryRepository repository = DiaryRepository();
  final SetupRepository setupRepository = SetupRepository();
  final today =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

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
      final diary = await repository.getDiary(today);
      if (diary != null) {
        List<Diary> unfilterDiaries = [diary];
        List<Diary> unSubmittedDiaries = unfilterDiaries
            .where((element) => element.status == DiaryStatus.complete)
            .toList();
        List<Diary> diaries = unfilterDiaries
            .where((element) => element.status != DiaryStatus.complete)
            .toList();
        diaries
            .sort((a, b) => a.status.toString().compareTo(b.status.toString()));
        emit(HomeLoaded(diaries, unSubmittedDiaries));
      }
    } catch (e) {
      emit(const HomeError("Something went wrong"));
    }
  }

  Future<String> getParticipantName() async =>
      setupRepository.getParticipant()!.name;

  Future<List<Diary>> getAllDiaries() async => repository.getAllDiaries();

  List<Diary> getAllDiariesThisWeek() {
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
            element.due.isAfter(monday) && element.due.isBefore(sunday))
        .toList();
    thisWeek.sort((a, b) => a.due.compareTo(b.due));
    return thisWeek;
  }
}
