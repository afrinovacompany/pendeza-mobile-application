import 'package:equatable/equatable.dart';
import 'package:pendeza/features/2_client_appointments/domain/models/appointment_with_details.dart';

abstract class AppointmentsState extends Equatable {
  const AppointmentsState();

  @override
  List<Object> get props => [];
}

class AppointmentsInitial extends AppointmentsState {}

class AppointmentsLoading extends AppointmentsState {}

/// ENHANCED: Now includes pendingPaymentAppointments for proper status handling
class AppointmentsLoaded extends AppointmentsState {
  /// Appointments that are awaiting payment completion
  /// These should be shown prominently with a "Complete Payment" action
  final List<AppointmentWithDetails> pendingPaymentAppointments;

  /// Appointments that are confirmed (paid) and scheduled for the future
  final List<AppointmentWithDetails> upcomingAppointments;

  /// Appointments that are completed, cancelled, or in the past
  final List<AppointmentWithDetails> pastAppointments;

  const AppointmentsLoaded({
    this.pendingPaymentAppointments = const [],
    required this.upcomingAppointments,
    required this.pastAppointments,
  });

  /// Helper: Check if there are any pending payments requiring action
  bool get hasPendingPayments => pendingPaymentAppointments.isNotEmpty;

  /// Helper: Total count of appointments requiring attention
  int get actionRequiredCount => pendingPaymentAppointments.length;

  /// Helper: Combined count of active appointments (pending + upcoming)
  int get activeAppointmentsCount =>
      pendingPaymentAppointments.length + upcomingAppointments.length;

  @override
  List<Object> get props => [
    pendingPaymentAppointments,
    upcomingAppointments,
    pastAppointments,
  ];
}

class AppointmentsError extends AppointmentsState {
  final String message;

  const AppointmentsError(this.message);

  @override
  List<Object> get props => [message];
}