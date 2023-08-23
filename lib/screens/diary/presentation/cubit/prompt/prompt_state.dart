part of 'prompt_cubit.dart';

sealed class PromptState extends Equatable {
  const PromptState();

  @override
  List<Object> get props => [];
}

final class PromptInitial extends PromptState {
  const PromptInitial();
}

final class PromptLoading extends PromptState {
  const PromptLoading();
}

final class PromptLoaded extends PromptState {
  final Prompt prompt;
  const PromptLoaded(this.prompt);

  @override
  List<Object> get props => [prompt];
}

final class PromptRespondState extends PromptState {
  const PromptRespondState();
}

final class PromptResponseError extends PromptState {
  const PromptResponseError();
}

final class PromptResponseSuccess extends PromptState {
  const PromptResponseSuccess();
}
