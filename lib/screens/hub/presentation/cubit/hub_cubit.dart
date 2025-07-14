import 'package:audio_diaries_flutter/core/usecases/experiment_manager.dart';
import 'package:audio_diaries_flutter/core/services/remote_config_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'hub_state.dart';

class HubCubit extends Cubit<HubState> {
  //handles the state of the hub screen, including refreshing and updating experiments as well as listening for remote config updates
  final RemoteConfigService _remoteConfigService;

  HubCubit({RemoteConfigService? remoteConfigService})
      : _remoteConfigService = remoteConfigService ?? RemoteConfigService(),
        super(const HubInitial()) {
    _initializeRemoteConfigListener();
  }

  void _initializeRemoteConfigListener() {
    _remoteConfigService.versionUpdateCounter
        .addListener(_onRemoteConfigUpdate);
  }

  void _onRemoteConfigUpdate() {
    if (!isClosed) {
      update();
      emit(const HubInitial());
    }
  }

  update() async {
    if (isClosed) return;

    emit(const HubUpdating());
    final done = await ExperimentManager().update();

    if (!isClosed) {
      emit(HubUpdated(done));
      emit(const HubInitial());
    }
  }

  @override
  Future<void> close() {
    _remoteConfigService.versionUpdateCounter
        .removeListener(_onRemoteConfigUpdate);
    return super.close();
  }
}
