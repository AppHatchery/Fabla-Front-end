import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/participant.dart';

part 'setup_state.dart';

class SetupCubit extends Cubit<SetupState> {
  SetupCubit() : super(const SetupInitial());
  final SetupRepository repository = SetupRepository();

  void load() async {
    emit(const SetupLoading());
    try {
      final participant = repository.getParticipant();
      emit(SetupLoaded(participant));
    } catch (e) {
      debugPrint(e.toString());
      emit(const SetupError("Something went wrong"));
    }
  }

  void updateParticipant(String name) {
    emit(const SetupLoading());
    try {
      repository.updateParticipant(name);
      emit(const SetupSuccess());
    } catch (e) {
      debugPrint(e.toString());
      emit(const SetupError("Something went wrong"));
    }
  }
}
