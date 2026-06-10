part of 'hub_cubit.dart';

sealed class HubState extends Equatable {
  const HubState();

  @override
  List<Object> get props => [];
}

class HubInitial extends HubState {
  const HubInitial();
}

class HubUpdating extends HubState {
  const HubUpdating();
}

class HubRefreshing extends HubState {}

class HubUpdated extends HubState {}

class HubUpdateAvailable extends HubState {}

class HubUpdateFailed extends HubState {
  final bool connectionError;
  const HubUpdateFailed({this.connectionError = false});

  @override
  List<Object> get props => [connectionError];
}
