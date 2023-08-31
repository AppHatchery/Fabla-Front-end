import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/participant.dart';

part 'setup_state.dart';

class SetupCubit extends Cubit<SetupState> {
  SetupCubit() : super(const SetupInitial());
  final SetupRepository repository = SetupRepository();

  /// Loads participant data and updates the state accordingly.
  ///
  /// This function is responsible for loading participant data from the repository.
  /// It emits different states to reflect the loading process and outcome:
  ///   - `SetupLoading`: Indicates that the loading process has started.
  ///   - `SetupLoaded`: Indicates that the participant data has been successfully loaded
  ///                    and provides the loaded participant information.
  ///   - `SetupError`: Indicates that an error occurred during the loading process
  ///                   and provides an error message.
  ///
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

  /// Updates the participant's name and reflects the state changes.
  ///
  /// This function is responsible for updating the participant's name using the
  /// provided [name]. It emits different states to reflect the update process and outcome:
  ///   - `SetupLoading`: Indicates that the update process has started.
  ///   - `SetupSuccess`: Indicates that the participant's name has been successfully updated.
  ///   - `SetupError`: Indicates that an error occurred during the update process
  ///                   and provides an error message.
  ///
  /// Parameters:
  /// - [name]: The new name to be assigned to the participant.
  ///
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
