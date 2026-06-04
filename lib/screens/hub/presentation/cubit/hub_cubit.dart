import 'package:audio_diaries_flutter/core/usecases/experiment_manager.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
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

  void update() async {
    emit(HubUpdating());
    final done = await _experimentManager.update();

    if (done) {
      await _experimentManager.setUpdateStatus(UpdateStatus.none);
    }

    emit(HubUpdated(done));

    emit(const HubInitial());
  }

  void scheduleForLater() async {
    await _experimentManager.setUpdateStatus(UpdateStatus.pending);
  }

  void refresh() {
    emit(HubRefreshing());
  }

  void checkForUpdates() async {
    final state = await _experimentManager.checkForUpdates();
    if (state == UpdateStatus.available) {
      emit(HubUpdateAvailable());
    } else if (state == UpdateStatus.pending) {
      // TODO: cross-check scheduled job
    }
  }
}
