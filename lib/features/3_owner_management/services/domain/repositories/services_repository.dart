import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';

abstract class ServicesRepository {
  Future<List<ServiceModel>> getServices(String salonId);
  Future<void> addService(ServiceModel service);
  Future<void> updateService(ServiceModel service);
  Future<void> deleteService(String serviceId);
  Future<SalonModel?> getSalonForOwner(String ownerId);
}
