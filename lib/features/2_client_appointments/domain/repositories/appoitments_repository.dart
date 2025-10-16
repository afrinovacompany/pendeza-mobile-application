import 'package:pendeza/features/2_client_appointments/domain/models/appointment_with_details.dart';

abstract class AppointmentsRepository {
  /// Fetches a list of appointments for a given client ID, complete with
  /// details about the salon and services.
  Future<List<AppointmentWithDetails>> getAppointments(String clientId);
}
