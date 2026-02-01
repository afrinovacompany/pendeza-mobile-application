import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';

/// Booking flow status enum
enum BookingStatus {
  initial,
  loadingServices,
  selectingServices,
  selectingTime,
  reviewing,
  processing,
  success,
  failure,
}

/// Base class for booking states
abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

/// Initial state before booking starts
class BookingInitial extends BookingState {}

/// In-progress booking with all current selections
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

  /// Calculate total price of selected services
  double get totalPrice =>
      selectedServices.fold(0.0, (sum, s) => sum + s.price);

  /// Calculate total duration of selected services
  int get totalDurationMinutes =>
      selectedServices.fold(0, (sum, s) => sum + s.durationMinutes);

  /// Check if ready to proceed to time selection
  bool get canSelectTime => selectedServices.isNotEmpty;

  /// Check if ready to review booking
  bool get canReview =>
      selectedServices.isNotEmpty &&
          selectedDate != null &&
          selectedTimeSlot != null;

  @override
  List<Object?> get props => [
    salon,
    status,
    availableServices,
    selectedServices,
    selectedDate,
    selectedTimeSlot,
    availableTimeSlots,
    errorMessage,
  ];

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
}

/// Booking created, now requires payment to confirm
/// This is the KEY state that triggers the payment flow
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
  List<Object?> get props => [
    appointmentId,
    amount,
    salon,
    services,
    appointmentDateTime,
  ];
}

/// Booking was successful (for free bookings or after payment)
class BookingSuccess extends BookingState {
  final String appointmentId;
  final String message;

  const BookingSuccess({
    required this.appointmentId,
    this.message = 'Booking confirmed successfully!',
  });

  @override
  List<Object?> get props => [appointmentId, message];
}

/// Booking failed with error message
class BookingFailure extends BookingState {
  final String error;
  final bool isGuestAttempt;

  const BookingFailure({
    required this.error,
    this.isGuestAttempt = false,
  });

  @override
  List<Object?> get props => [error, isGuestAttempt];
}