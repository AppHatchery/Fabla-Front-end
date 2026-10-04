part of 'diary_session_cubit.dart';

sealed class DiarySessionState extends Equatable {
  const DiarySessionState();

  @override
  List<Object?> get props => [];
}

final class DiarySessionLoading extends DiarySessionState {
  const DiarySessionLoading();
}

final class DiarySessionReady extends DiarySessionState {
  final List<PromptModel> visiblePrompts;

  const DiarySessionReady({required this.visiblePrompts});

  @override
  List<Object?> get props => [visiblePrompts];
}

final class DiarySessionResponseSaved extends DiarySessionState {
  final int promptId;
  final PromptModel updatedPrompt;

  const DiarySessionResponseSaved({
    required this.promptId,
    required this.updatedPrompt,
  });

  @override
  List<Object?> get props => [promptId, updatedPrompt];
}

final class DiarySessionResponseDeleted extends DiarySessionState {
  final int promptId;

  const DiarySessionResponseDeleted({required this.promptId});

  @override
  List<Object?> get props => [promptId];
}

final class DiarySessionError extends DiarySessionState {
  final String message;

  const DiarySessionError(this.message);

  @override
  List<Object?> get props => [message];
}
