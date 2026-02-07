import 'package:pendeza/shared/models/appointment_model.dart';
import '../../../../0_auth/data/models/user_model.dart';
import '../models/client_stats.dart';


/// Repository for managing client data and analytics
abstract class ClientManagementRepository {
  /// Fetches all unique clients for a salon
  Future<List<ClientStats>> getAllClientsForSalon(String salonId);

  /// Fetches detailed stats for a specific client
  Future<ClientStats> getClientStats(String salonId, String clientId);

  /// Fetches all appointments for a specific client at a salon
  Future<List<AppointmentModel>> getClientAppointments(
      String salonId,
      String clientId,
      );

  /// Fetches user details for a client
  Future<UserModel> getClientDetails(String clientId);

  /// Searches clients by name or phone
  Future<List<ClientStats>> searchClients(String salonId, String query);
}