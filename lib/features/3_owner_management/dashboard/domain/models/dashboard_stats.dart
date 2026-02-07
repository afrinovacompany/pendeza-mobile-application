import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/appointment_model.dart';

/// Model representing dashboard statistics
class DashboardStats extends Equatable {
  final double todayRevenue;
  final int todayAppointmentsCount;
  final int newClientsThisWeek;
  final double occupancyRate;
  final List<AppointmentModel> upcomingToday;
  /// All upcoming appointments across the next 7 days (includes today)
  final List<AppointmentModel> upcomingAll;
  final DateTime lastUpdated;

  const DashboardStats({
    required this.todayRevenue,
    required this.todayAppointmentsCount,
    required this.newClientsThisWeek,
    required this.occupancyRate,
    required this.upcomingToday,
    this.upcomingAll = const [],
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
    todayRevenue,
    todayAppointmentsCount,
    newClientsThisWeek,
    occupancyRate,
    upcomingToday,
    upcomingAll,
    lastUpdated,
  ];

  /// Creates empty stats for initial state
  factory DashboardStats.empty() {
    return DashboardStats(
      todayRevenue: 0,
      todayAppointmentsCount: 0,
      newClientsThisWeek: 0,
      occupancyRate: 0,
      upcomingToday: [],
      upcomingAll: [],
      lastUpdated: DateTime.now(),
    );
  }

  DashboardStats copyWith({
    double? todayRevenue,
    int? todayAppointmentsCount,
    int? newClientsThisWeek,
    double? occupancyRate,
    List<AppointmentModel>? upcomingToday,
    List<AppointmentModel>? upcomingAll,
    DateTime? lastUpdated,
  }) {
    return DashboardStats(
      todayRevenue: todayRevenue ?? this.todayRevenue,
      todayAppointmentsCount:
      todayAppointmentsCount ?? this.todayAppointmentsCount,
      newClientsThisWeek: newClientsThisWeek ?? this.newClientsThisWeek,
      occupancyRate: occupancyRate ?? this.occupancyRate,
      upcomingToday: upcomingToday ?? this.upcomingToday,
      upcomingAll: upcomingAll ?? this.upcomingAll,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}