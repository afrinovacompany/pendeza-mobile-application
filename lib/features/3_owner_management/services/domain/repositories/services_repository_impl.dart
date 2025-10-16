import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/features/3_owner_management/services/domain/repositories/services_repository.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final FirestoreService _firestoreService;

  ServicesRepositoryImpl(this._firestoreService);

  @override
  Future<List<ServiceModel>> getServices(String salonId) {
    return _firestoreService.getServicesForSalon(salonId);
  }

  @override
  Future<void> addService(ServiceModel service) {
    return _firestoreService.addService(service);
  }

  @override
  Future<void> updateService(ServiceModel service) {
    return _firestoreService.updateService(service);
  }

  @override
  Future<void> deleteService(String serviceId) {
    return _firestoreService.deleteService(serviceId);
  }

  @override
  Future<SalonModel?> getSalonForOwner(String ownerId) {
    return _firestoreService.getSalonForOwner(ownerId: ownerId);
  }
}
