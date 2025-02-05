import 'package:audio_diaries_flutter/core/usecases/experiment_manager.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'hub_state.dart';

class HubCubit extends Cubit<HubState> {
  HubCubit() : super(const HubInitial());

  checkForUpdate() async {
    final update = await ExperimentManager().checkForUpdate();
    if (!update) {
      return;
    }

    emit(HubUpdating());
    await Future.delayed(const Duration(seconds: 2)); // TODO: Remove this line
    final done = await ExperimentManager().update();
    if (done) emit(HubUpdated());

    // TODO: Add Error Handling
    emit(HubInitial());
  }
}
