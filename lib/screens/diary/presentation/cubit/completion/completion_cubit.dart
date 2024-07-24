import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/protocol.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'completion_state.dart';

class CompletionCubit extends Cubit<CompletionState> {
  final SetupRepository _repository = SetupRepository();
  final DiaryRepository _diaryRepository = DiaryRepository();
  final SetupRepository setupRepository = SetupRepository();

  CompletionCubit() : super(const CompletionInitial());

  Future<void> completeDiary(DiaryModel diary) async {
    final today = DateTime.now();
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    String? studyCode = setupRepository.getParticipant()?.studyCode;
    bool showWidget = false;

    final source =
        await PreferenceService().getStringPreference(key: 'futureDate');
    final date = source ?? today;
    final futureDate = DateTime.parse(date.toString());

    try {
      emit(const CompletionLoading());
      final protocol = _repository.getProtocol();
      final newDiary = _diaryRepository.getDiaryByID(diary.id);
      final diaries = _diaryRepository.getRangeDiaries(
          monday.subtract(const Duration(days: 1)),
          sunday.add(const Duration(days: 1)));
      if (int.parse(studyCode!) % 2 == 0 && today.isBefore(futureDate)) {
        showWidget = true;
      } else if (int.parse(studyCode) % 2 == 0 && today.isAfter(futureDate)) {
        showWidget = false;
      } else if (int.parse(studyCode) % 2 != 0 && today.isBefore(futureDate)) {
        showWidget = false;
      } else if (int.parse(studyCode) % 2 != 0 && today.isAfter(futureDate)) {
        showWidget = true;
      }

      emit(CompletionLoaded(
          diary: newDiary!,
          diaries: diaries,
          protocol: protocol!,
          showWidget: showWidget));
    } catch (e) {
      safePrint(e.toString());
      emit(CompletionError(message: e.toString()));
    }
  }
}
