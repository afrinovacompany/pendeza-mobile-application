import 'package:equatable/equatable.dart';
import 'package:pendeza/features/2_client_appointments/domain/models/appointment_with_details.dart';

abstract class AppointmentsState extends Equatable {
  const AppointmentsState();

  @override
  List<Object> get props => [];
}

class AppointmentsInitial extends AppointmentsState {}

class AppointmentsLoading extends AppointmentsState {}

class AppointmentsLoaded extends AppointmentsState {
  final List<AppointmentWithDetails> upcomingAppointments;
  final List<AppointmentWithDetails> pastAppointments;

  const AppointmentsLoaded({
    required this.upcomingAppointments,
    required this.pastAppointments,
  });

  @override
  List<Object> get props => [upcomingAppointments, pastAppointments];
}

class AppointmentsError extends AppointmentsState {
  final String message;

  const AppointmentsError(this.message);

  @override
  List<Object> get props => [message];
}
