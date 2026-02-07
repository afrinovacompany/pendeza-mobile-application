import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/appointment_model.dart';

abstract class OwnerCalendarState extends Equatable {
  const OwnerCalendarState();

  @override
  List<Object> get props => [];
}

class OwnerCalendarInitial extends OwnerCalendarState {}

class OwnerCalendarLoading extends OwnerCalendarState {
  final DateTime loadingDate; // Keep track of which date is loading
  const OwnerCalendarLoading(this.loadingDate);
  @override
  List<Object> get props => [loadingDate];
}

class OwnerCalendarLoaded extends OwnerCalendarState {
  final List<AppointmentModel> appointments;
  final DateTime selectedDate;

  const OwnerCalendarLoaded(this.appointments, this.selectedDate);

  @override
  List<Object> get props => [appointments, selectedDate];
}

class OwnerCalendarError extends OwnerCalendarState {
  final String message;
  final DateTime errorDate; // Keep track of which date failed

  const OwnerCalendarError(this.message, this.errorDate);

  @override
  List<Object> get props => [message, errorDate];
}
