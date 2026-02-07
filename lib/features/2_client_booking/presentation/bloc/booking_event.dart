import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();
  @override
  List<Object?> get props => [];
}

/// Start with full model (Standard flow)
class StartBooking extends BookingEvent {
  final SalonModel salon;
  const StartBooking(this.salon);
  @override
  List<Object?> get props => [salon];
}

/// ✅ NEW: Start with just ID (Video Shorts/Deep Links)
class StartBookingWithId extends BookingEvent {
  final String salonId;
  const StartBookingWithId(this.salonId);
  @override
  List<Object?> get props => [salonId];
}

class FetchServicesForSalon extends BookingEvent {}

class ServicesSelected extends BookingEvent {
  final List<ServiceModel> services;
  const ServicesSelected(this.services);
  @override
  List<Object?> get props => [services];
}

class DateSelected extends BookingEvent {
  final DateTime date;
  const DateSelected(this.date);
  @override
  List<Object?> get props => [date];
}

class FetchTimeSlots extends BookingEvent {}

class TimeSlotSelected extends BookingEvent {
  final String timeSlot;
  const TimeSlotSelected(this.timeSlot);
  @override
  List<Object?> get props => [timeSlot];
}

class ConfirmBooking extends BookingEvent {}

class ResetBooking extends BookingEvent {}

class PaymentCompleted extends BookingEvent {
  final String appointmentId;
  final String transactionId;
  const PaymentCompleted({required this.appointmentId, required this.transactionId});
  @override
  List<Object?> get props => [appointmentId, transactionId];
}

class PaymentFailed extends BookingEvent {
  final String appointmentId;
  final String? reason;
  const PaymentFailed({required this.appointmentId, this.reason});
  @override
  List<Object?> get props => [appointmentId, reason];
}