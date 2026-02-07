import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import '../../../../0_auth/data/models/user_model.dart';
import '../../domain/models/client_stats.dart';

abstract class ClientDetailsState extends Equatable {
  const ClientDetailsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ClientDetailsInitial extends ClientDetailsState {
  const ClientDetailsInitial();
}

/// Loading client details
class ClientDetailsLoading extends ClientDetailsState {
  const ClientDetailsLoading();
}

/// Client details loaded successfully
class ClientDetailsLoaded extends ClientDetailsState {
  final ClientStats clientStats;
  final UserModel clientUser;
  final List<AppointmentModel> appointments;

  const ClientDetailsLoaded({
    required this.clientStats,
    required this.clientUser,
    required this.appointments,
  });

  @override
  List<Object?> get props => [clientStats, clientUser, appointments];
}

/// Error loading client details
class ClientDetailsError extends ClientDetailsState {
  final String message;

  const ClientDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}