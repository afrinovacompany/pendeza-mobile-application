import 'package:equatable/equatable.dart';

abstract class ClientManagementEvent extends Equatable {
  const ClientManagementEvent();

  @override
  List<Object?> get props => [];
}

/// Load all data (regulars + recent bookings)
class LoadClients extends ClientManagementEvent {
  const LoadClients();
}

/// Search clients by name or phone
class SearchClients extends ClientManagementEvent {
  final String query;

  const SearchClients(this.query);

  @override
  List<Object?> get props => [query];
}

/// Refresh data (pull to refresh)
class RefreshClients extends ClientManagementEvent {
  const RefreshClients();
}
