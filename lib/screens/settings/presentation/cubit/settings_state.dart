part of 'settings_cubit.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object> get props => [];
}

final class SettingsInitial extends SettingsState {}

final class SettingsLoading extends SettingsState {}

final class SettingsLoaded extends SettingsState {
  final List<Questions> onboardingQuestion;
  final String completedDate;
  const SettingsLoaded(
      {required this.onboardingQuestion, required this.completedDate});

  @override
  List<Object> get props => [onboardingQuestion, completedDate];
}

final class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);

  @override
  List<Object> get props => [message];
}
