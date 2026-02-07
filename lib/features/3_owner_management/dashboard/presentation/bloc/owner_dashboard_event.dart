import 'package:equatable/equatable.dart';

abstract class OwnerDashboardEvent extends Equatable {
  const OwnerDashboardEvent();

  @override
  List<Object> get props => [];
}

/// Event to load/refresh dashboard data
class LoadDashboardData extends OwnerDashboardEvent {
  const LoadDashboardData();
}

/// Event to refresh dashboard data (pull-to-refresh)
class RefreshDashboardData extends OwnerDashboardEvent {
  const RefreshDashboardData();
}