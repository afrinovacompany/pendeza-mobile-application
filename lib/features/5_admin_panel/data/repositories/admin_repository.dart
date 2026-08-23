import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/promotion_model.dart'; // Import this

abstract class AdminRepository {
  /// Fetches all users from the database.
  Future<List<UserModel>> getAllUsers();

  /// Fetches all salons from the database.
  Future<List<SalonModel>> getAllSalons();

  /// Recent appointments across all salons, newest start time first.
  Future<List<AppointmentModel>> getAllAppointments({int limit = 200});

  /// Resolves service document IDs to display names.
  Future<Map<String, String>> getServiceNamesByIds(Iterable<String> ids);

  /// Fetches all platform promotions.
  Future<List<PromotionModel>> getPlatformPromotions(); // NEW

  /// Updates a specific user's role.
  Future<void> updateUserRole(String uid, String newRole);

  /// Adds a new platform promotion.
  Future<void> addPromotion(PromotionModel promotion); // NEW

  /// Updates an existing platform promotion.
  Future<void> updatePromotion(PromotionModel promotion);

  /// Deletes a promotion.
  Future<void> deletePromotion(String promotionId); // NEW

  /// Approve a salon (set verificationStatus to 'approved')
  Future<void> approveSalon(String salonId);

  /// Reject a salon with a reason
  Future<void> rejectSalon(String salonId, String reason);
}