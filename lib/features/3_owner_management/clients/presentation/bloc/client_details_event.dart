import 'package:equatable/equatable.dart';

abstract class ClientDetailsEvent extends Equatable {
  const ClientDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load a specific client's details
class LoadClientDetails extends ClientDetailsEvent {
  final String clientId;

  const LoadClientDetails(this.clientId);

  @override
  List<Object?> get props => [clientId];
}

/// Event to refresh client details
class RefreshClientDetails extends ClientDetailsEvent {
  const RefreshClientDetails();
}