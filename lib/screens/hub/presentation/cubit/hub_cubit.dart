import 'package:audio_diaries_flutter/core/usecases/experiment_manager.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'hub_state.dart';

class HubCubit extends Cubit<HubState> {
  HubCubit() : super(const HubInitial());

  update() async {
    emit(HubUpdating());
    final done = await ExperimentManager().update();

    emit(HubUpdated(done));

    emit(const HubInitial());
  }
}
