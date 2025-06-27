import 'package:audio_diaries_flutter/core/usecases/experiment_manager.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'hub_state.dart';

class HubCubit extends Cubit<HubState> {
  /// The experiment manager instance used for updates.
  /// If not provided, a default instance will be created.
  final ExperimentManager _experimentManager;

  /// Creates a HubCubit with optional dependency injection.
  ///
  /// [experimentManager] can be provided for testing purposes.
  /// If not provided, a default ExperimentManager instance will be used.
  HubCubit({ExperimentManager? experimentManager})
      : _experimentManager = experimentManager ?? ExperimentManager(),
        super(const HubInitial());

  update() async {
    emit(HubUpdating());
    final done = await _experimentManager.update();

    emit(HubUpdated(done));

    emit(const HubInitial());
  }
}
