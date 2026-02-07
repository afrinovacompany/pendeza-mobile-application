import 'package:equatable/equatable.dart';

abstract class ClientManagementEvent extends Equatable {
  const ClientManagementEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all clients for the salon
class LoadClients extends ClientManagementEvent {
  const LoadClients();
}

/// Event to search clients
class SearchClients extends ClientManagementEvent {
  final String query;

  const SearchClients(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event to load a specific client's details
class LoadClientDetails extends ClientManagementEvent {
  final String clientId;

  const LoadClientDetails(this.clientId);

  @override
  List<Object?> get props => [clientId];
}

/// Event to refresh client list
class RefreshClients extends ClientManagementEvent {
  const RefreshClients();
}