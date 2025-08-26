import 'package:audio_diaries_flutter/core/usecases/experiment_manager.dart';
import 'package:audio_diaries_flutter/core/services/remote_config_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'hub_state.dart';

class HubCubit extends Cubit<HubState> {
  /// Experiment manager for handling experiment updates.
  final ExperimentManager _experimentManager;

  /// Remote config service for listening to version updates.
  final RemoteConfigService _remoteConfigService;

  /// Creates a HubCubit with optional dependency injection.
  ///
  /// If not provided, default instances will be created.
  HubCubit({
    ExperimentManager? experimentManager,
    RemoteConfigService? remoteConfigService,
  })  : _experimentManager = experimentManager ?? ExperimentManager(),
        _remoteConfigService = remoteConfigService ?? RemoteConfigService(),
        super(const HubInitial()) {
    _initializeRemoteConfigListener();
  }

  void _initializeRemoteConfigListener() {
    _remoteConfigService.versionUpdateCounter.addListener(_onRemoteConfigUpdate);
  }

  void _onRemoteConfigUpdate() {
    if (!isClosed) {
      update();
    }
  }

  Future<void> update() async {
    emit(HubUpdating());
    final done = await _experimentManager.update();

    if (!isClosed) {
      emit(HubUpdated(done));
      emit(const HubInitial());
    }
  }

  void refresh() {
    emit(HubRefreshing());
  }

  @override
  Future<void> close() {
    _remoteConfigService.versionUpdateCounter.removeListener(_onRemoteConfigUpdate);
    return super.close();
  }
}
