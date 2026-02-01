import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/features/3_owner_management/services/domain/repositories/services_repository.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/app/utils/logger.dart'; // Import logger

class ServicesRepositoryImpl implements ServicesRepository {
  final FirestoreService _firestoreService;

  ServicesRepositoryImpl(this._firestoreService);

  @override
  Future<List<ServiceModel>> getServices(String salonId) {
    log.i('Fetching services for salon: $salonId');
    return _firestoreService.getServicesForSalon(salonId);
  }

  @override
  Future<void> addService(ServiceModel service) {
    log.i('Adding new service: ${service.name}');
    return _firestoreService.addService(service);
  }

  @override
  Future<void> updateService(ServiceModel service) {
    log.i('Updating service: ${service.id}');
    return _firestoreService.updateService(service);
  }

  @override
  Future<void> deleteService(String serviceId) {
    log.i('Deleting service: $serviceId');
    return _firestoreService.deleteService(serviceId);
  }

  @override
  Future<SalonModel?> getSalonForOwner(String ownerId) {
    log.i('Fetching salon for owner: $ownerId');
    return _firestoreService.getSalonForOwner(ownerId: ownerId);
  }
}