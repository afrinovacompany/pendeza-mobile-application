import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';

abstract class BookingRepository {
  Future<List<SalonModel>> getSalons();
  Future<SalonModel> getSalonDetails(String salonId);
  Future<List<ServiceModel>> getServicesForSalon(String salonId);

  // CHANGE: Return String (ID)
  Future<String> createAppointment(AppointmentModel appointment);

  // === NEW METHOD ===
  /// Fetches appointments for a specific salon on a given date.
  Future<List<AppointmentModel>> getAppointmentsForSalonOnDate(
      String salonId, DateTime date);
// ==================
}