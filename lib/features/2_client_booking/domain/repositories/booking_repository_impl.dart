import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/features/2_client_booking/domain/repositories/booking_repository.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/shared/models/staff_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final FirestoreService _firestoreService;

  BookingRepositoryImpl(this._firestoreService);

  @override
  Future<List<SalonModel>> getSalons() {
    return _firestoreService.getSalons();
  }

  @override
  Future<SalonModel> getSalonDetails(String salonId) {
    return _firestoreService.getSalonDetails(salonId);
  }

  @override
  Future<List<ServiceModel>> getServicesForSalon(String salonId) {
    return _firestoreService.getServicesForSalon(salonId);
  }

  @override
  Future<List<StaffModel>> getStaffForSalon(String salonId) {
    return _firestoreService.getStaffForSalon(salonId);
  }

  @override
  Future<void> createAppointment(AppointmentModel appointment) {
    return _firestoreService.createAppointment(appointment);
  }
}
