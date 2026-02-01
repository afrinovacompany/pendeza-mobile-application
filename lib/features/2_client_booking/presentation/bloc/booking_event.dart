import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';

/// Base class for booking events
abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

/// Start a new booking flow for a salon
class StartBooking extends BookingEvent {
  final SalonModel salon;

  const StartBooking(this.salon);

  @override
  List<Object?> get props => [salon];
}

/// Fetch available services for the current salon
class FetchServicesForSalon extends BookingEvent {}

/// User has selected services
class ServicesSelected extends BookingEvent {
  final List<ServiceModel> services;

  const ServicesSelected(this.services);

  @override
  List<Object?> get props => [services];
}

/// User has selected a date
class DateSelected extends BookingEvent {
  final DateTime date;

  const DateSelected(this.date);

  @override
  List<Object?> get props => [date];
}

/// Fetch available time slots for the selected date
class FetchTimeSlots extends BookingEvent {}

/// User has selected a time slot
class TimeSlotSelected extends BookingEvent {
  final String timeSlot;

  const TimeSlotSelected(this.timeSlot);

  @override
  List<Object?> get props => [timeSlot];
}

/// User confirms the booking (triggers payment flow)
class ConfirmBooking extends BookingEvent {}

/// Reset the booking flow
class ResetBooking extends BookingEvent {}

/// Payment was completed successfully (called after webhook confirms)
class PaymentCompleted extends BookingEvent {
  final String appointmentId;
  final String transactionId;

  const PaymentCompleted({
    required this.appointmentId,
    required this.transactionId,
  });

  @override
  List<Object?> get props => [appointmentId, transactionId];
}

/// Payment failed or was cancelled
class PaymentFailed extends BookingEvent {
  final String appointmentId;
  final String? reason;

  const PaymentFailed({
    required this.appointmentId,
    this.reason,
  });

  @override
  List<Object?> get props => [appointmentId, reason];
}