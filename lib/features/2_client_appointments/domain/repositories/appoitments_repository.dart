import 'package:pendeza/features/2_client_appointments/domain/models/appointment_with_details.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';

abstract class AppointmentsRepository {
  /// Fetches appointments for a given CLIENT ID (Existing method)
  Future<List<AppointmentWithDetails>> getAppointments(String clientId);

  /// Fetches confirmed appointments for a given SALON ID on a specific DATE
  Future<List<AppointmentModel>> getConfirmedAppointmentsForSalon(
      String salonId, DateTime date);

  /// Fetches the salon profile for a given OWNER ID
  Future<SalonModel?> getSalonForOwner(String ownerId);
}