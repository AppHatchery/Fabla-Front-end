part of 'setup_cubit.dart';

sealed class SetupState extends Equatable {
  const SetupState();

  @override
  List<Object> get props => [];
}

final class SetupInitial extends SetupState {
  const SetupInitial();
}

final class SetupLoading extends SetupState {
  const SetupLoading();
}

final class SetupLoaded extends SetupState {
  final Participant? participant;
  const SetupLoaded(this.participant);
}

final class SetupError extends SetupState {
  final String message;
  const SetupError(this.message);
}

final class SetupSuccess extends SetupState {
  const SetupSuccess();
}
