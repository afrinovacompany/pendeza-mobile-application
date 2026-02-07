import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/promotion_model.dart';

abstract class OwnerPromotionsState extends Equatable {
  const OwnerPromotionsState();

  @override
  List<Object?> get props => [];
}

class OwnerPromotionsInitial extends OwnerPromotionsState {}

class OwnerPromotionsLoading extends OwnerPromotionsState {}

class OwnerPromotionsLoaded extends OwnerPromotionsState {
  final List<PromotionModel> promotions;

  const OwnerPromotionsLoaded(this.promotions);

  @override
  List<Object?> get props => [promotions];
}

class OwnerPromotionsError extends OwnerPromotionsState {
  final String message;

  const OwnerPromotionsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State emitted when a promotion is successfully created.
/// UI should listen for this to pop the screen or show a success snackbar.
class PromotionOperationSuccess extends OwnerPromotionsState {
  final String message;

  const PromotionOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Special state: Creation paused, waiting for payment.
/// UI should navigate to PaymentScreen.
class PromotionPaymentRequired extends OwnerPromotionsState {
  final double amount;
  final String orderId; // Can use this to track the payment

  const PromotionPaymentRequired({
    required this.amount,
    required this.orderId,
  });

  @override
  List<Object?> get props => [amount, orderId];
}