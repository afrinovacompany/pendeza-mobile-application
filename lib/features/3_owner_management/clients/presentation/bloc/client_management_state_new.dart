import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import '../../domain/models/regular_client.dart';

abstract class ClientManagementState extends Equatable {
  const ClientManagementState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ClientManagementInitial extends ClientManagementState {
  const ClientManagementInitial();
}

/// Loading state
class ClientManagementLoading extends ClientManagementState {
  const ClientManagementLoading();
}

/// Loaded state with all data
class ClientManagementLoaded extends ClientManagementState {
  final List<RegularClient> regularClients; // Top clients (5+ visits)
  final List<AppointmentModel> recentBookings; // Last 10 appointments
  final List<RegularClient>? searchResults; // Populated during search

  const ClientManagementLoaded({
    required this.regularClients,
    required this.recentBookings,
    this.searchResults,
  });

  /// Check if currently searching
  bool get isSearching => searchResults != null;

  @override
  List<Object?> get props => [regularClients, recentBookings, searchResults];

  /// Create copy with updated search results
  ClientManagementLoaded copyWith({
    List<RegularClient>? regularClients,
    List<AppointmentModel>? recentBookings,
    List<RegularClient>? searchResults,
    bool clearSearch = false,
  }) {
    return ClientManagementLoaded(
      regularClients: regularClients ?? this.regularClients,
      recentBookings: recentBookings ?? this.recentBookings,
      searchResults: clearSearch ? null : (searchResults ?? this.searchResults),
    );
  }
}

/// Error state
class ClientManagementError extends ClientManagementState {
  final String message;

  const ClientManagementError(this.message);

  @override
  List<Object?> get props => [message];
}
