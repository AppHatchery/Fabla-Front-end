import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/utils/statuses.dart';
import '../../../data/diary.dart';

part 'diary_state.dart';

class DiaryCubit extends Cubit<DiaryState>{
  DiaryCubit() : super(const DiaryInitial());
  DiaryRepository repository = DiaryRepository();
  final today =
  DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  Future<void> loadDiaries() async{
    try{
      emit(const DiaryLoading());
      final diary = await repository.getDiary(today);
      if(diary != null){
        List<Diary> unfilterDiaries = [diary];
        List<Diary> unSubmittedDiaries = unfilterDiaries
            .where((element) => element.status == DiaryStatus.complete)
            .toList();
        List<Diary> diaries = unfilterDiaries
            .where((element) => element.status != DiaryStatus.complete)
            .toList();
        diaries
            .sort((a, b) => a.status.toString().compareTo(b.status.toString()));
        emit(DiaryLoaded(diaries, unSubmittedDiaries));
      }else{
        emit(const DiaryLoaded([], []));
      }
    } catch(e){
      emit(const DiaryError("Something went wrong"));
    }
  }

}