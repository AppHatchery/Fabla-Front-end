import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/utils/statuses.dart';
import '../../../data/diary.dart';

part  'diary_history_state.dart';

class DiaryHistoryCubit extends Cubit<DiaryHistoryState>{
  DiaryHistoryCubit() : super(const DiaryHistoryInitial());
  DiaryRepository repository = DiaryRepository();


  Future<void> loadPastDiaries() async{
    try{
      emit(const DiaryHistoryLoading());
      //final diary = await repository.getAllDiaries();
      List<Diary> unfilteredDiaries = await repository.getAllDiaries();
      List<Diary> unSubmittedDiaries = unfilteredDiaries
          .where((element) => element.status == DiaryStatus.complete)
          .toList();
      List<Diary> diaries = unfilteredDiaries
          .where((element) => element.status != DiaryStatus.complete)
          .toList();
      diaries
          .sort((a, b) => a.status.toString().compareTo(b.status.toString()));
      emit(DiaryHistoryLoaded(diaries, unSubmittedDiaries));
    } catch(e){
      emit(const DiaryHistoryError("Something went wrong"));
    }
  }
}
