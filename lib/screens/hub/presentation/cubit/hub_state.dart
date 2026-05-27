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

class HubUpdated extends HubState {
  final bool complete;
  const HubUpdated(this.complete);

  @override
  List<Object> get props => [complete];
}

class HubUpdateAvailable extends HubState {}
