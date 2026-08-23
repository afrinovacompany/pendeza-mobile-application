import 'package:equatable/equatable.dart';

abstract class OwnerCalendarEvent extends Equatable {
  const OwnerCalendarEvent();

  @override
  List<Object> get props => [];
}

/// Event to load appointments for a specific date
class LoadAppointmentsForDate extends OwnerCalendarEvent {
  final DateTime date;

  const LoadAppointmentsForDate(this.date);

  @override
  List<Object> get props => [date];
}

class CreateWalkInAppointment extends OwnerCalendarEvent {
  final String clientName;
  final String serviceId;
  final int durationMinutes;
  final double totalPrice;
  final DateTime startTime;

  const CreateWalkInAppointment({
    required this.clientName,
    required this.serviceId,
    required this.durationMinutes,
    required this.totalPrice,
    required this.startTime,
  });

  @override
  List<Object> get props =>
      [clientName, serviceId, durationMinutes, totalPrice, startTime];
}
