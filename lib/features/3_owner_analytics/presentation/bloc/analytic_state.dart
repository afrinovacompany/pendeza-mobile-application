// lib/features/3_owner_management/presentation/bloc/analytics_state.dart
import 'package:equatable/equatable.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object> get props => [];
}

class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

class AnalyticsLoading extends AnalyticsState {
  const AnalyticsLoading();
}

class AnalyticsLoaded extends AnalyticsState {
  final List<double> weeklyRevenue;
  final Map<String, int> servicePopularity;
  final List<MapEntry<String, int>> topServices;

  const AnalyticsLoaded({
    required this.weeklyRevenue,
    required this.servicePopularity,
    required this.topServices,
  });

  @override
  List<Object> get props => [weeklyRevenue, servicePopularity, topServices];
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError(this.message);

  @override
  List<Object> get props => [message];
}