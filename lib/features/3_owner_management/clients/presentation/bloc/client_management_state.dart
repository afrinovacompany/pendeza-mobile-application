import 'package:equatable/equatable.dart';
import '../../domain/models/client_stats.dart';


abstract class ClientManagementState extends Equatable {
  const ClientManagementState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ClientManagementInitial extends ClientManagementState {
  const ClientManagementInitial();
}

/// Loading clients
class ClientManagementLoading extends ClientManagementState {
  const ClientManagementLoading();
}

/// Clients loaded successfully
class ClientManagementLoaded extends ClientManagementState {
  final List<ClientStats> clients;
  final String? searchQuery;

  const ClientManagementLoaded({
    required this.clients,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [clients, searchQuery];
}

/// Error loading clients
class ClientManagementError extends ClientManagementState {
  final String message;

  const ClientManagementError(this.message);

  @override
  List<Object?> get props => [message];
}