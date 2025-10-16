import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/features/3_owner_management/staff/domain/repository/staff_repository.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/staff_model.dart';

class StaffRepositoryImpl implements StaffRepository {
  final FirestoreService _firestoreService;

  StaffRepositoryImpl(this._firestoreService);

  @override
  Future<List<StaffModel>> getStaff(String salonId) {
    return _firestoreService.getStaffForSalon(salonId);
  }

  @override
  Future<void> addStaff(StaffModel staff) {
    return _firestoreService.addStaff(staff);
  }

  @override
  Future<void> updateStaff(StaffModel staff) {
    return _firestoreService.updateStaff(staff);
  }

  @override
  Future<void> deleteStaff(String staffId) {
    return _firestoreService.deleteStaff(staffId);
  }

  @override
  Future<SalonModel?> getSalonForOwner(String ownerId) {
    return _firestoreService.getSalonForOwner(ownerId: ownerId);
  }
}
