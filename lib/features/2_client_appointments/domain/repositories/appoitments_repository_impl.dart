import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/features/2_client_appointments/domain/models/appointment_with_details.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';

import 'appoitments_repository.dart';

class AppointmentsRepositoryImpl implements AppointmentsRepository {
  final FirestoreService _firestoreService;

  AppointmentsRepositoryImpl(this._firestoreService);

  @override
  Future<List<AppointmentWithDetails>> getAppointments(String clientId) async {
    // 1. Fetch the raw appointment data
    final List<AppointmentModel> rawAppointments =
    await _firestoreService.getAppointmentsForClient(clientId);

    if (rawAppointments.isEmpty) {
      return [];
    }

    // 2. Fetch all unique salon and service details in parallel to be efficient
    final salonIds = rawAppointments.map((e) => e.salonId).toSet();
    final serviceIds =
    rawAppointments.expand((e) => e.serviceIds).toSet();

    final salonFutures =
    salonIds.map((id) => _firestoreService.getSalonDetails(id));
    final serviceFutures =
    serviceIds.map((id) => _firestoreService.getServiceDetails(id));

    final results = await Future.wait([
      Future.wait(salonFutures),
      Future.wait(serviceFutures),
    ]);

    final salons = results[0] as List<SalonModel>;
    final services = results[1] as List<ServiceModel>;

    // 3. Create maps for easy lookup
    final salonMap = {for (var salon in salons) salon.id: salon};
    final serviceMap = {for (var service in services) service.id: service};

    // 4. Combine the data into our rich model
    final detailedAppointments = rawAppointments.map((appointment) {
      return AppointmentWithDetails(
        appointment: appointment,
        salon: salonMap[appointment.salonId]!,
        services: appointment.serviceIds
            .map((serviceId) => serviceMap[serviceId]!)
            .toList(),
      );
    }).toList();

    return detailedAppointments;
  }
}
