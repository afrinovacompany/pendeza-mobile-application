import 'dart:io';
import 'package:pendeza/shared/models/promotion_model.dart';

abstract class OwnerPromotionsRepository {
  /// Fetches all promotions for a specific salon.
  /// Returns a stream to listen for real-time updates (stats, active status).
  Stream<List<PromotionModel>> getPromotionsStream(String salonId);

  /// Creates a new promotion in the salon's subcollection.
  /// Handles image upload if a file is provided.
  Future<void> createPromotion({
    required String salonId,
    required PromotionModel promotion,
    required File imageFile,
  });

  /// Deletes a promotion and its associated image.
  Future<void> deletePromotion({
    required String salonId,
    required String promotionId,
    required String imageUrl,
  });

  /// Toggles whether a promotion is active or paused.
  Future<void> togglePromotionStatus({
    required String salonId,
    required String promotionId,
    required bool isActive,
  });

  /// Activates the "Featured" status after a successful payment.
  /// Sets [isFeatured] to true and [featuredUntil] to 7 days from now.
  Future<void> boostPromotion({
    required String salonId,
    required String promotionId,
  });
}