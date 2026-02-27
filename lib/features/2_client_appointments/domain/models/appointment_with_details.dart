
import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';

/// A rich data model that combines a raw appointment with its related
/// salon and service details for easy display in the UI.
class AppointmentWithDetails extends Equatable {
  final AppointmentModel appointment;
  final SalonModel salon;
  final List<ServiceModel> services;

  const AppointmentWithDetails({
    required this.appointment,
    required this.salon,
    required this.services,
  });

  /// A computed property to get a comma-separated string of service names.
  String get serviceNames => services.map((s) => s.name).join(', ');

  @override
  List<Object?> get props => [appointment, salon, services];
}
