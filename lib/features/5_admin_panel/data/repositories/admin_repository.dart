import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/promotion_model.dart'; // Import this

abstract class AdminRepository {
  /// Fetches all users from the database.
  Future<List<UserModel>> getAllUsers();

  /// Fetches all salons from the database.
  Future<List<SalonModel>> getAllSalons();

  /// Fetches all platform promotions.
  Future<List<PromotionModel>> getPlatformPromotions(); // NEW

  /// Updates a specific user's role.
  Future<void> updateUserRole(String uid, String newRole);

  /// Adds a new platform promotion.
  Future<void> addPromotion(PromotionModel promotion); // NEW

  /// Deletes a promotion.
  Future<void> deletePromotion(String promotionId); // NEW
}