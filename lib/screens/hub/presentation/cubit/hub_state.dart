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

class HubUpdated extends HubState {
  const HubUpdated();
}
