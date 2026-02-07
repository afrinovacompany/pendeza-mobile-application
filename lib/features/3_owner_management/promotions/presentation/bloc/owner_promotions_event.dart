import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/promotion_model.dart';

abstract class OwnerPromotionsEvent extends Equatable {
  const OwnerPromotionsEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening to the promotions stream for a specific salon.
class LoadOwnerPromotions extends OwnerPromotionsEvent {
  final String salonId;

  const LoadOwnerPromotions(this.salonId);

  @override
  List<Object?> get props => [salonId];
}

/// Internal event used when the stream emits new data.
class UpdatePromotionsList extends OwnerPromotionsEvent {
  final List<PromotionModel> promotions;

  const UpdatePromotionsList(this.promotions);

  @override
  List<Object?> get props => [promotions];
}

/// Submit the creation form.
class CreateSalonPromotion extends OwnerPromotionsEvent {
  final String salonId;
  final PromotionModel promotion;
  final File imageFile;
  final bool shouldBoost; // Trigger payment flow if true

  const CreateSalonPromotion({
    required this.salonId,
    required this.promotion,
    required this.imageFile,
    this.shouldBoost = false,
  });

  @override
  List<Object?> get props => [salonId, promotion, imageFile, shouldBoost];
}

/// Delete an existing promotion.
class DeleteSalonPromotion extends OwnerPromotionsEvent {
  final String salonId;
  final String promotionId;
  final String imageUrl;

  const DeleteSalonPromotion({
    required this.salonId,
    required this.promotionId,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [salonId, promotionId, imageUrl];
}

/// Toggle active/inactive status.
class ToggleSalonPromotionStatus extends OwnerPromotionsEvent {
  final String salonId;
  final String promotionId;
  final bool isActive;

  const ToggleSalonPromotionStatus({
    required this.salonId,
    required this.promotionId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [salonId, promotionId, isActive];
}

/// Boost an existing promotion (e.g. if payment was done separately).
class BoostSalonPromotion extends OwnerPromotionsEvent {
  final String salonId;
  final String promotionId;

  const BoostSalonPromotion({
    required this.salonId,
    required this.promotionId,
  });

  @override
  List<Object?> get props => [salonId, promotionId];
}