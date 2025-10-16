import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import '../../../../shared/models/service_model.dart';
import '../../../../shared/models/staff_model.dart';

enum BookingStatus {
  initial,
  inProgress,
  loadingServices,
  loadingStaff,
  loading,
  success,
  failure
}

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingInProgress extends BookingState {
  final SalonModel salon;
  final List<ServiceModel> availableServices;
  final List<ServiceModel> selectedServices;
  final StaffModel? selectedStaff;
  final DateTime? selectedDateTime;
  final BookingStatus status;

  const BookingInProgress({
    required this.salon,
    this.availableServices = const [],
    this.selectedServices = const [],
    this.selectedStaff,
    this.selectedDateTime,
    this.status = BookingStatus.inProgress,
  });

  BookingInProgress copyWith({
    SalonModel? salon,
    List<ServiceModel>? availableServices,
    List<ServiceModel>? selectedServices,
    StaffModel? selectedStaff,
    DateTime? selectedDateTime,
    BookingStatus? status,
  }) {
    return BookingInProgress(
      salon: salon ?? this.salon,
      availableServices: availableServices ?? this.availableServices,
      selectedServices: selectedServices ?? this.selectedServices,
      selectedStaff: selectedStaff ?? this.selectedStaff,
      selectedDateTime: selectedDateTime ?? this.selectedDateTime,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    salon,
    availableServices,
    selectedServices,
    selectedStaff,
    selectedDateTime,
    status
  ];
}

class BookingSuccess extends BookingState {
  const BookingSuccess();
}

class BookingFailure extends BookingState {
  final String error;

  const BookingFailure(this.error);

  @override
  List<Object> get props => [error];
}
