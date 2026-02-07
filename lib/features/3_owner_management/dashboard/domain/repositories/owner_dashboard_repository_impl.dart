import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/shared/models/service_model.dart'; // Added this import
import 'owner_dashboard_repository.dart';

class OwnerDashboardRepositoryImpl implements OwnerDashboardRepository {
  final FirestoreService _firestoreService;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  OwnerDashboardRepositoryImpl(this._firestoreService);

  @override
  Future<SalonModel?> getSalonForOwner(String ownerId) {
    return _firestoreService.getSalonForOwner(ownerId: ownerId);
  }

  @override
  Future<List<AppointmentModel>> getAppointmentsForDate(
      String salonId,
      DateTime date,
      ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _db
          .collection('appointments')
          .where('salonId', isEqualTo: salonId)
          .where('startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e, s) {
      log.e('Error fetching appointments for date', error: e, stackTrace: s);
      return [];
    }
  }

  @override
  Future<List<AppointmentModel>> getAppointmentsForDateRange(
      String salonId,
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      final snapshot = await _db
          .collection('appointments')
          .where('salonId', isEqualTo: salonId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e, s) {
      log.e('Error fetching appointments for date range',
          error: e, stackTrace: s);
      return [];
    }
  }

  @override
  Future<int> getTotalClientsCount(String salonId) async {
    try {
      final snapshot = await _db
          .collection('appointments')
          .where('salonId', isEqualTo: salonId)
          .get();

      // Get unique client IDs
      final clientIds = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc).clientId)
          .toSet();

      return clientIds.length;
    } catch (e, s) {
      log.e('Error fetching total clients count', error: e, stackTrace: s);
      return 0;
    }
  }

  @override
  Future<int> getNewClientsCount(
      String salonId,
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      // Get all appointments in date range
      final recentSnapshot = await _db
          .collection('appointments')
          .where('salonId', isEqualTo: salonId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      // Get all appointments before start date
      final previousSnapshot = await _db
          .collection('appointments')
          .where('salonId', isEqualTo: salonId)
          .where('startTime', isLessThan: Timestamp.fromDate(start))
          .get();

      // Get unique client IDs from recent appointments
      final recentClients = recentSnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc).clientId)
          .toSet();

      // Get unique client IDs from previous appointments
      final previousClients = previousSnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc).clientId)
          .toSet();

      // New clients are those in recent but not in previous
      final newClients = recentClients.difference(previousClients);

      return newClients.length;
    } catch (e, s) {
      log.e('Error fetching new clients count', error: e, stackTrace: s);
      return 0;
    }
  }

  // Added the new method implementation
  @override
  Future<List<ServiceModel>> getServicesForSalon(String salonId) async {
    try {
      final snapshot = await _db
          .collection('salons')
          .doc(salonId)
          .collection('services')
          .get();
      return snapshot.docs.map((doc) => ServiceModel.fromFirestore(doc)).toList();
    } catch (e, s) {
      log.e('Error fetching services', error: e, stackTrace: s);
      return [];
    }
  }
}