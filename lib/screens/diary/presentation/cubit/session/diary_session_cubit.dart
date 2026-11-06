import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/answer.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/prompt_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'diary_session_state.dart';

class DiarySessionCubit extends Cubit<DiarySessionState> {
  DiarySessionCubit() : super(const DiarySessionLoading());

  final PromptRepository _repository = PromptRepository();

  DiaryModel? _diary;
  List<PromptModel> _allPrompts = [];
  Map<int, Answer> _answers = {};

  void init(DiaryModel diary) {
    _diary = diary;
    emit(const DiarySessionLoading());

    try {
      final session = _repository.loadSession(diary);
      _allPrompts = session.prompts;
      _answers = session.answers;
      emit(DiarySessionReady(visiblePrompts: _computeVisible()));
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          reason: 'DiarySessionCubit.init');
      emit(DiarySessionError(e.toString()));
    }
  }

  Future<void> saveAnswer({
    required PromptModel prompt,
    required dynamic response,
    required String type,
    int? index,
  }) async {
    if (_diary == null) return;

    try {
      final saved = _repository.saveResponse(
        diary: Diary.fromModel(_diary!),
        prompt: prompt,
        response: response,
        type: type,
        index: index,
      );

      if (!saved) return;

      final refreshed = _repository.loadPromptWithAnswer(_diary!, prompt.id);
      _updateCache(refreshed);

      // Walk all prompts in question_number order. Prompts that are answered
      // but whose conditions are no longer met (old branch) have their answers
      // cleared so they don't appear in the summary or get submitted.
      for (final p in _allPrompts) {
        if (_answers.containsKey(p.questionNumber) && !p.shouldShow(_answers)) {
          final freshPrompt = _repository.loadPromptWithAnswer(_diary!, p.id);
          await _repository.clearAnswer(_diary!, freshPrompt);
          _answers.remove(p.questionNumber);
        }
      }

      emit(DiarySessionResponseSaved(
        promptId: prompt.id,
        updatedPrompt: refreshed,
      ));
      emit(DiarySessionReady(visiblePrompts: _computeVisible()));
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          reason: 'DiarySessionCubit.saveAnswer');
      dev.log('Error saving answer: $e', name: 'DiarySessionCubit');
    }
  }

  Future<void> removeAnswer({
    required PromptModel prompt,
    required String? path,
    int? index,
  }) async {
    if (_diary == null) return;

    try {
      final removed = await _repository.removeResponse(
        Diary.fromModel(_diary!),
        prompt,
        path,
        index: index,
      );

      if (!removed) return;

      final refreshed = _repository.loadPromptWithAnswer(_diary!, prompt.id);
      _updateCache(refreshed);

      emit(DiarySessionResponseDeleted(promptId: prompt.id));
      emit(DiarySessionReady(visiblePrompts: _computeVisible()));
    } catch (e, stackTrace) {
      CrashlyticsService().recordError(e, stackTrace,
          reason: 'DiarySessionCubit.removeAnswer');
    }
  }

  List<PromptModel> _computeVisible() {
    return _allPrompts.where((p) => p.shouldShow(_answers)).toList();
  }

  void _updateCache(PromptModel refreshed) {
    final idx = _allPrompts.indexWhere((p) => p.id == refreshed.id);
    if (idx >= 0) _allPrompts[idx] = refreshed;

    final answer = refreshed.answer;
    if (answer != null) {
      _answers[refreshed.questionNumber] = answer;
    } else {
      _answers.remove(refreshed.questionNumber);
    }
  }
}
