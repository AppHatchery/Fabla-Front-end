import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/login_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
part 'study_login_state.dart';

class StudyLoginCubit extends Cubit<StudyLoginState> {
  StudyLoginCubit() : super(const StudyLoginInitial());
  final LoginRepository repository = LoginRepository();

  void login(String code) async {
    emit(const StudyLoginLoading());
    try {
      final result = await repository.studyVerification(code);
      if (result != null) {
        emit(StudyLoginSuccess(result));
      } else {
        emit(const StudyLoginError(
            "Oops! We do not have this code in the study list. Please check your email and try again."));
      }
    } catch (e) {
      emit(const StudyLoginError("Something went wrong. Please try again."));
    }
  }
}
