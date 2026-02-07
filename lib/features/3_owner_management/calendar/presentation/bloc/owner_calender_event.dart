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
