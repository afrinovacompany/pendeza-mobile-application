import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/app/utils/logger.dart';
import '../../../../0_auth/data/models/user_model.dart';
import '../models/client_stats.dart';
import 'client_management_repository.dart';


class ClientManagementRepositoryImpl implements ClientManagementRepository {
  final FirestoreService _firestoreService;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ClientManagementRepositoryImpl(this._firestoreService);

  @override
  Future<List<ClientStats>> getAllClientsForSalon(String salonId) async {
    try {
      log.i('Fetching all clients for salon: $salonId');

      // Get all appointments for the salon
      final appointmentsSnapshot = await _db
          .collection('appointments')
          .where('salonId', isEqualTo: salonId)
          .get();

      // Group appointments by client
      final clientAppointmentsMap = <String, List<AppointmentModel>>{};
      for (final doc in appointmentsSnapshot.docs) {
        final appointment = AppointmentModel.fromFirestore(doc);
        clientAppointmentsMap.putIfAbsent(
          appointment.clientId,
              () => [],
        ).add(appointment);
      }

      // Calculate stats for each client
      final clientStatsList = <ClientStats>[];
      for (final entry in clientAppointmentsMap.entries) {
        final clientId = entry.key;
        final appointments = entry.value;

        try {
          final clientUser = await _firestoreService.getUserDetails(clientId);
          final stats = _calculateClientStats(clientUser, appointments);
          clientStatsList.add(stats);
        } catch (e) {
          log.w('Could not fetch details for client $clientId: $e');
        }
      }

      // Sort by last visit (most recent first)
      clientStatsList.sort((a, b) => b.lastVisit.compareTo(a.lastVisit));

      log.i('Found ${clientStatsList.length} unique clients');
      return clientStatsList;
    } catch (e, s) {
      log.e('Error fetching clients for salon', error: e, stackTrace: s);
      return [];
    }
  }

  @override
  Future<ClientStats> getClientStats(String salonId, String clientId) async {
    try {
      log.i('Fetching stats for client: $clientId');

      final appointments = await getClientAppointments(salonId, clientId);
      final clientUser = await _firestoreService.getUserDetails(clientId);

      return _calculateClientStats(clientUser, appointments);
    } catch (e, s) {
      log.e('Error fetching client stats', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<List<AppointmentModel>> getClientAppointments(
      String salonId,
      String clientId,
      ) async {
    try {
      final snapshot = await _db
          .collection('appointments')
          .where('salonId', isEqualTo: salonId)
          .where('clientId', isEqualTo: clientId)
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e, s) {
      log.e('Error fetching client appointments', error: e, stackTrace: s);
      return [];
    }
  }

  @override
  Future<UserModel> getClientDetails(String clientId) {
    return _firestoreService.getUserDetails(clientId);
  }

  @override
  Future<List<ClientStats>> searchClients(String salonId, String query) async {
    try {
      if (query.isEmpty) {
        return getAllClientsForSalon(salonId);
      }

      final allClients = await getAllClientsForSalon(salonId);
      final lowerQuery = query.toLowerCase();

      // Filter by name or phone
      return allClients.where((client) {
        final nameMatch = client.clientName.toLowerCase().contains(lowerQuery);
        final phoneMatch =
            client.phoneNumber?.toLowerCase().contains(lowerQuery) ?? false;
        return nameMatch || phoneMatch;
      }).toList();
    } catch (e, s) {
      log.e('Error searching clients', error: e, stackTrace: s);
      return [];
    }
  }

  /// Helper method to calculate client statistics
  ClientStats _calculateClientStats(
      UserModel user,
      List<AppointmentModel> appointments,
      ) {
    final totalAppointments = appointments.length;
    final completedAppointments = appointments
        .where((a) => a.status.toLowerCase() == 'completed')
        .length;
    final cancelledAppointments = appointments
        .where((a) => a.status.toLowerCase() == 'cancelled')
        .length;

    final totalSpent = appointments
        .where((a) => a.status.toLowerCase() == 'completed')
        .fold<double>(0.0, (sum, a) => sum + a.totalPrice);

    // Sort by date to get first and last visit
    final sortedAppointments = List<AppointmentModel>.from(appointments)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final firstVisit = sortedAppointments.isNotEmpty
        ? sortedAppointments.first.startTime
        : DateTime.now();
    final lastVisit = sortedAppointments.isNotEmpty
        ? sortedAppointments.last.startTime
        : DateTime.now();

    // Find most booked services
    final serviceCount = <String, int>{};
    for (final appointment in appointments) {
      for (final serviceId in appointment.serviceIds) {
        serviceCount[serviceId] = (serviceCount[serviceId] ?? 0) + 1;
      }
    }

    // Get top 3 services
    final favoriteServices = serviceCount.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topServices =
    favoriteServices.take(3).map((e) => e.key).toList();

    return ClientStats(
      clientId: user.uid,
      clientName: user.fullName,
      phoneNumber: user.phoneNumber,
      email: user.email,
      profilePictureUrl: user.profilePictureUrl,
      totalAppointments: totalAppointments,
      completedAppointments: completedAppointments,
      cancelledAppointments: cancelledAppointments,
      totalSpent: totalSpent,
      firstVisit: firstVisit,
      lastVisit: lastVisit,
      favoriteServices: topServices,
    );
  }
}