import 'package:pendeza/shared/models/staff_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';

abstract class StaffRepository {
  Future<List<StaffModel>> getStaff(String salonId);
  Future<void> addStaff(StaffModel staff);
  Future<void> updateStaff(StaffModel staff);
  Future<void> deleteStaff(String staffId);
  Future<SalonModel?> getSalonForOwner(String ownerId);
}
