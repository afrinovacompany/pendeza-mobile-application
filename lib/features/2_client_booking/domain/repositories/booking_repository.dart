import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/shared/models/staff_model.dart';

abstract class BookingRepository {
  Future<List<SalonModel>> getSalons();
  Future<SalonModel> getSalonDetails(String salonId);
  Future<List<ServiceModel>> getServicesForSalon(String salonId);
  Future<List<StaffModel>> getStaffForSalon(String salonId);
  Future<void> createAppointment(AppointmentModel appointment);
}
