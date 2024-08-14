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
  final ExperimentModel experiment;
  const StudyLoginSuccess(this.experiment);

  @override
  List<Object> get props => [experiment];
}

final class StudyLoginError extends StudyLoginState {
  final String message;
  const StudyLoginError(this.message);

  @override
  List<Object> get props => [message];
}
