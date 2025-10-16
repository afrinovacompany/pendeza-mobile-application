import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import '../../../../shared/models/service_model.dart';
import '../../../../shared/models/staff_model.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object> get props => [];
}

class StartBooking extends BookingEvent {
  final SalonModel salon;

  const StartBooking(this.salon);

  @override
  List<Object> get props => [salon];
}

/// Event to fetch services for the selected salon
class FetchServicesForSalon extends BookingEvent {}

/// Event to fetch staff for the selected salon
class FetchStaffForSalon extends BookingEvent {}

class SelectServices extends BookingEvent {
  final List<ServiceModel> services;

  const SelectServices(this.services);

  @override
  List<Object> get props => [services];
}

class SelectStaff extends BookingEvent {
  final StaffModel staff;

  const SelectStaff(this.staff);

  @override
  List<Object> get props => [staff];
}

class SelectDateTime extends BookingEvent {
  final DateTime dateTime;

  const SelectDateTime(this.dateTime);

  @override
  List<Object> get props => [dateTime];
}

class ConfirmBooking extends BookingEvent {}
