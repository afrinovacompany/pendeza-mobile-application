import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';

/// Booking flow status enum
enum BookingStatus {
  initial,
  loading, // Used when fetching salon by ID
  loadingServices,
  selectingServices,
  selectingTime,
  reviewing,
  processing,
  success,
  failure,
}

abstract class BookingState extends Equatable {
  const BookingState();
  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingInProgress extends BookingState {
  final SalonModel salon;
  final BookingStatus status;
  final List<ServiceModel> availableServices;
  final List<ServiceModel> selectedServices;
  final DateTime? selectedDate;
  final String? selectedTimeSlot;
  final List<String> availableTimeSlots;
  final String? errorMessage;

  const BookingInProgress({
    required this.salon,
    required this.status,
    required this.availableServices,
    required this.selectedServices,
    this.selectedDate,
    this.selectedTimeSlot,
    required this.availableTimeSlots,
    this.errorMessage,
  });

  // ✅ ADDED THIS BACK: Required for TimeslotSelectionScreen
  int get totalDurationMinutes =>
      selectedServices.fold(0, (sum, service) => sum + service.durationMinutes);

  double get totalPrice =>
      selectedServices.fold(0, (sum, item) => sum + item.price);

  BookingInProgress copyWith({
    SalonModel? salon,
    BookingStatus? status,
    List<ServiceModel>? availableServices,
    List<ServiceModel>? selectedServices,
    DateTime? selectedDate,
    String? selectedTimeSlot,
    List<String>? availableTimeSlots,
    String? errorMessage,
  }) {
    return BookingInProgress(
      salon: salon ?? this.salon,
      status: status ?? this.status,
      availableServices: availableServices ?? this.availableServices,
      selectedServices: selectedServices ?? this.selectedServices,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTimeSlot: selectedTimeSlot ?? this.selectedTimeSlot,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    salon, status, availableServices, selectedServices,
    selectedDate, selectedTimeSlot, availableTimeSlots, errorMessage,
  ];
}

class BookingPaymentRequired extends BookingState {
  final String appointmentId;
  final double amount;
  final SalonModel salon;
  final List<ServiceModel> services;
  final DateTime appointmentDateTime;

  const BookingPaymentRequired({
    required this.appointmentId,
    required this.amount,
    required this.salon,
    required this.services,
    required this.appointmentDateTime,
  });

  @override
  List<Object?> get props => [appointmentId, amount, salon, services, appointmentDateTime];
}

class BookingSuccess extends BookingState {
  final String appointmentId;
  final String message;
  const BookingSuccess({required this.appointmentId, this.message = 'Booking confirmed successfully!'});
  @override
  List<Object?> get props => [appointmentId, message];
}

class BookingFailure extends BookingState {
  final String error;
  final bool isGuestAttempt;
  const BookingFailure({required this.error, this.isGuestAttempt = false});
  @override
  List<Object?> get props => [error, isGuestAttempt];
}