import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart'; // Added this import

/// Repository for fetching owner dashboard analytics data
abstract class OwnerDashboardRepository {
  /// Fetches the salon for the current owner
  Future<SalonModel?> getSalonForOwner(String ownerId);

  /// Fetches all appointments for the salon on a specific date
  Future<List<AppointmentModel>> getAppointmentsForDate(
      String salonId,
      DateTime date,
      );

  /// Fetches appointments for a date range
  Future<List<AppointmentModel>> getAppointmentsForDateRange(
      String salonId,
      DateTime startDate,
      DateTime endDate,
      );

  /// Fetches all unique clients who have booked with the salon
  Future<int> getTotalClientsCount(String salonId);

  /// Fetches all services offered by the salon
  Future<List<ServiceModel>> getServicesForSalon(String salonId);

  /// Fetches new clients within a date range
  Future<int> getNewClientsCount(
      String salonId,
      DateTime startDate,
      DateTime endDate,
      );
}