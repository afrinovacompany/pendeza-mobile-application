import 'package:equatable/equatable.dart';

abstract class AppointmentsEvent extends Equatable {
  const AppointmentsEvent();

  @override
  List<Object> get props => [];
}

/// Event triggered to fetch all appointments for the current user.
class FetchAppointmentsRequested extends AppointmentsEvent {}
