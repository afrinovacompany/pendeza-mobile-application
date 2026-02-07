import 'package:equatable/equatable.dart';
import '../../domain/models/dashboard_stats.dart';


abstract class OwnerDashboardState extends Equatable {
  const OwnerDashboardState();

  @override
  List<Object> get props => [];
}

/// Initial state
class OwnerDashboardInitial extends OwnerDashboardState {
  const OwnerDashboardInitial();
}

/// Loading dashboard data
class OwnerDashboardLoading extends OwnerDashboardState {
  const OwnerDashboardLoading();
}

/// Dashboard data loaded successfully
class OwnerDashboardLoaded extends OwnerDashboardState {
  final DashboardStats stats;
  final String salonName;

  const OwnerDashboardLoaded({
    required this.stats,
    required this.salonName,
  });

  @override
  List<Object> get props => [stats, salonName];
}

/// Error loading dashboard data
class OwnerDashboardError extends OwnerDashboardState {
  final String message;

  const OwnerDashboardError(this.message);

  @override
  List<Object> get props => [message];
}