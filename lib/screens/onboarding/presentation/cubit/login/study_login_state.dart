part of 'study_login_cubit.dart';

sealed class StudyLoginState extends Equatable {
  const StudyLoginState();

  @override
  List<Object> get props => [];
}

final class StudyLoginInitial extends StudyLoginState {
  const StudyLoginInitial();
}

final class StudyLoginLoading extends StudyLoginState {
  const StudyLoginLoading();
}

final class StudyLoginSuccess extends StudyLoginState {
  const StudyLoginSuccess();
}

final class StudyLoginError extends StudyLoginState {
  final String message;
  const StudyLoginError(this.message);
}
