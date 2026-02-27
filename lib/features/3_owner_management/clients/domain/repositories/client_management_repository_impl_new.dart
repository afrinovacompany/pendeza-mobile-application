import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/app/utils/logger.dart';
import '../models/regular_client.dart';
import 'client_management_repository_new.dart';

class ClientManagementRepositoryImpl implements ClientManagementRepository {
  final FirestoreService _firestoreService;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ClientManagementRepositoryImpl(this._firestoreService);

  @override
  Future<List<RegularClient>> getRegularClients(String salonId) async {
    try {
      log.i('Fetching regular clients for salon: $salonId');

      // Get all appointments for this salon
      final appointmentsSnapshot = await _db
          .collection('appointments')
          .where('salonId', isEqualTo: salonId)
          .where('status', isEqualTo: 'Completed') // Only count completed visits
          .get();

      // Group by client and count visits
      final clientVisits = <String, List<DateTime>>{};
      for (final doc in appointmentsSnapshot.docs) {
        final appointment = AppointmentModel.fromFirestore(doc);
        clientVisits.putIfAbsent(appointment.clientId, () => [])
            .add(appointment.startTime);
      }

      // Filter clients with 2+ visits and fetch their details
      final regularClients = <RegularClient>[];
      for (final entry in clientVisits.entries) {
        final clientId = entry.key;
        final visits = entry.value;

        // Must have at least 2 visits to be considered
        if (visits.length < 2) continue;

        try {
          // Get user details
          final user = await _firestoreService.getUserDetails(clientId);

          // Sort visits to get most recent
          visits.sort((a, b) => b.compareTo(a));
          final lastVisit = visits.first;

          regularClients.add(RegularClient.fromData(
            userId: user.uid,
            userName: user.fullName,
            userPhone: user.phoneNumber,
            userPhotoUrl: user.profilePictureUrl,
            lastVisitDate: lastVisit,
            totalVisits: visits.length,
          ));
        } catch (e) {
          log.w('Could not fetch user details for $clientId: $e');
          continue;
        }
      }

      // Sort by visit count (most visits first), then by recency
      regularClients.sort((a, b) {
        final countCompare = b.visitCount.compareTo(a.visitCount);
        if (countCompare != 0) return countCompare;
        return b.lastVisit.compareTo(a.lastVisit);
      });

      // Return top 8
      final topClients = regularClients.take(8).toList();
      log.i('Found ${topClients.length} regular clients');
      return topClients;
    } catch (e, s) {
      log.e('Error fetching regular clients', error: e, stackTrace: s);
      return [];
    }
  }

  @override
  Future<List<AppointmentModel>> getRecentBookings(String salonId) async {
    try {
      log.i('Fetching recent bookings for salon: $salonId');

      final snapshot = await _db
          .collection('appointments')
          .where('salonId', isEqualTo: salonId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();

      log.i('Found ${appointments.length} recent bookings');
      return appointments;
    } catch (e, s) {
      log.e('Error fetching recent bookings', error: e, stackTrace: s);
      return [];
    }
  }

  @override
  Future<List<RegularClient>> searchClients(String salonId, String query) async {
    try {
      if (query.isEmpty) return [];

      log.i('Searching clients for: $query');

      // Get all unique clients from appointments
      final appointmentsSnapshot = await _db
          .collection('appointments')
          .where('salonId', isEqualTo: salonId)
          .get();

      final uniqueClientIds = <String>{};
      for (final doc in appointmentsSnapshot.docs) {
        final appointment = AppointmentModel.fromFirestore(doc);
        uniqueClientIds.add(appointment.clientId);
      }

      // Fetch all client details and filter by query
      final searchResults = <RegularClient>[];
      final lowerQuery = query.toLowerCase();

      for (final clientId in uniqueClientIds) {
        try {
          final user = await _firestoreService.getUserDetails(clientId);

          // Check if name or phone matches
          final nameMatch = user.fullName.toLowerCase().contains(lowerQuery);
          final phoneMatch = user.phoneNumber?.toLowerCase().contains(lowerQuery) ?? false;

          if (nameMatch || phoneMatch) {
            // Get visit count and last visit for this client
            final clientAppointments = appointmentsSnapshot.docs
                .map((doc) => AppointmentModel.fromFirestore(doc))
                .where((apt) => apt.clientId == clientId && apt.status == 'Completed')
                .toList();

            if (clientAppointments.isEmpty) continue;

            clientAppointments.sort((a, b) => b.startTime.compareTo(a.startTime));
            final lastVisit = clientAppointments.first.startTime;

            searchResults.add(RegularClient.fromData(
              userId: user.uid,
              userName: user.fullName,
              userPhone: user.phoneNumber,
              userPhotoUrl: user.profilePictureUrl,
              lastVisitDate: lastVisit,
              totalVisits: clientAppointments.length,
            ));
          }
        } catch (e) {
          log.w('Could not fetch user $clientId: $e');
          continue;
        }
      }

      // Sort by visit count
      searchResults.sort((a, b) => b.visitCount.compareTo(a.visitCount));

      log.i('Found ${searchResults.length} matching clients');
      return searchResults;
    } catch (e, s) {
      log.e('Error searching clients', error: e, stackTrace: s);
      return [];
    }
  }
}
