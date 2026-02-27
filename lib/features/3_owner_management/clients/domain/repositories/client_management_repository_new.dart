import 'package:pendeza/shared/models/appointment_model.dart';
import '../models/regular_client.dart';

/// Simple repository for client management
abstract class ClientManagementRepository {
  /// Get top clients (sorted by visit count, minimum 2 visits)
  /// Returns max 8 clients for the "Regulars" section
  Future<List<RegularClient>> getRegularClients(String salonId);

  /// Get last 10 appointments for the salon
  Future<List<AppointmentModel>> getRecentBookings(String salonId);

  /// Search all clients by name or phone
  Future<List<RegularClient>> searchClients(String salonId, String query);
}
