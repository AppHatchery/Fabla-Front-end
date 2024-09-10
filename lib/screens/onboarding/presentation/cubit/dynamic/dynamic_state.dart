part of 'dynamic_cubit.dart';

sealed class DynamicState extends Equatable {
  const DynamicState();

  @override
  List<Object> get props => [];
}

final class DynamicInitial extends DynamicState {}

final class DynamicLoading extends DynamicState {}

final class DynamicLoaded extends DynamicState {
  final List<Questions> questions;
  const DynamicLoaded({required this.questions});

  @override
  List<Object> get props => [questions];
}

final class DynamicNone extends DynamicState {}

final class DynamicError extends DynamicState {
  final String message;
  const DynamicError(this.message);

  @override
  List<Object> get props => [message];
}

final class DynamicUploading extends DynamicState {}

final class DynamicUploaded extends DynamicState {}
