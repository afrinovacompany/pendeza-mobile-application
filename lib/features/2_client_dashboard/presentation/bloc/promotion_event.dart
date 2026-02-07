import 'package:equatable/equatable.dart';

abstract class PromotionsEvent extends Equatable {
  const PromotionsEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch promotions for the main dashboard
class LoadDashboardPromotions extends PromotionsEvent {}

/// Refresh the promotions (e.g., pull-to-refresh)
class RefreshPromotions extends PromotionsEvent {}