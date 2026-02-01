import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/features/2_client_appointments/domain/models/appointment_with_details.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/app/utils/logger.dart';

import 'appoitments_repository.dart';

class AppointmentsRepositoryImpl implements AppointmentsRepository {
  final FirestoreService _firestoreService;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppointmentsRepositoryImpl(this._firestoreService);

  @override
  Future<List<AppointmentWithDetails>> getAppointments(String clientId) async {
    log.d("Fetching appointments for client: $clientId");
    final List<AppointmentModel> rawAppointments =
    await _firestoreService.getAppointmentsForClient(clientId);
    log.d(
        "Found ${rawAppointments.length} raw appointments for client $clientId");

    if (rawAppointments.isEmpty) {
      return [];
    }

    // --- NEW: Resilient Fetching Logic ---
    // Instead of Future.wait, we fetch salons and services individually
    // so one error doesn't break the whole list.

    // 1. Fetch all unique salons
    final salonIds = rawAppointments.map((e) => e.salonId).toSet();
    final salonMap = <String, SalonModel>{};
    for (String id in salonIds) {
      try {
        final salon = await _firestoreService.getSalonDetails(id);
        salonMap[id] = salon;
      } catch (e, s) {
        log.e("Failed to fetch salon details for salonId: $id",
            error: e, stackTrace: s);
        // If a salon fails, we'll skip appointments for it later
      }
    }
    log.d("Successfully fetched ${salonMap.length} salons");

    // 2. Fetch all unique services
    final serviceIds = rawAppointments.expand((e) => e.serviceIds).toSet();
    final serviceMap = <String, ServiceModel>{};
    for (String id in serviceIds) {
      try {
        final service = await _firestoreService.getServiceDetails(id);
        serviceMap[id] = service;
      } catch (e, s) {
        log.e("Failed to fetch service details for serviceId: $id",
            error: e, stackTrace: s);
        // If a service fails, we'll skip appointments that need it
      }
    }
    log.d("Successfully fetched ${serviceMap.length} services");

    // 3. Map appointments, checking for missing data
    final detailedAppointments = <AppointmentWithDetails>[];
    for (var appointment in rawAppointments) {
      // Check if salon was fetched
      final salon = salonMap[appointment.salonId];
      if (salon == null) {
        log.w(
            "Skipping appointment ${appointment.id}: Salon ${appointment.salonId} could not be loaded.");
        continue;
      }

      // Check if ALL services for this appointment were fetched
      final appointmentServices = <ServiceModel>[];
      bool allServicesFound = true;
      for (String serviceId in appointment.serviceIds) {
        final service = serviceMap[serviceId];
        if (service == null) {
          log.w(
              "Skipping appointment ${appointment.id}: Service $serviceId could not be loaded (likely deleted).");
          allServicesFound = false;
          break; // Stop checking services for this appointment
        }
        appointmentServices.add(service);
      }

      if (allServicesFound) {
        detailedAppointments.add(AppointmentWithDetails(
          appointment: appointment,
          salon: salon,
          services: appointmentServices,
        ));
      }
    }
    // --- End of Resilient Logic ---

    log.d(
        "Returning ${detailedAppointments.length} detailed (and valid) appointments for client $clientId");
    return detailedAppointments;
  }

  /// Implementation for getConfirmedAppointmentsForSalon
  @override
  Future<List<AppointmentModel>> getConfirmedAppointmentsForSalon(
      String salonId, DateTime date) async {
    log.d(
        "Fetching confirmed appointments for salon: $salonId on date: ${date.toIso8601String()}");
    try {
      // Calculate start and end of the selected day
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _db
          .collection('appointments')
          .where('salonId', isEqualTo: salonId)
      // We can also query for 'Confirmed' status if needed
      // .where('status', isEqualTo: 'Confirmed')
          .where('startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('startTime', descending: false)
          .get();

      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
      // Filter out cancelled appointments on the client side
          .where((app) => app.status != 'Cancelled')
          .toList();

      log.d(
          "Found ${appointments.length} appointments for salon $salonId on ${date.toIso8601String()}");
      return appointments;
    } catch (e, s) {
      log.e("Error fetching appointments for salon $salonId on $date",
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Implementation for getSalonForOwner (delegates to FirestoreService)
  @override
  Future<SalonModel?> getSalonForOwner(String ownerId) {
    log.d("Fetching salon for owner: $ownerId via AppointmentsRepository");
    return _firestoreService.getSalonForOwner(ownerId: ownerId);
  }
}