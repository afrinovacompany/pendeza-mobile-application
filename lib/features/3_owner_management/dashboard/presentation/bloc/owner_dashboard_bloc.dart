import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/app/utils/logger.dart';
import '../../../../../shared/models/appointment_model.dart';
import '../../../../../shared/models/service_model.dart';
import '../../domain/models/dashboard_stats.dart';
import '../../domain/models/go_live_checklist.dart';
import '../../domain/repositories/owner_dashboard_repository.dart';
import 'owner_dashboard_event.dart';
import 'owner_dashboard_state.dart';


class OwnerDashboardBloc
    extends Bloc<OwnerDashboardEvent, OwnerDashboardState> {
  final OwnerDashboardRepository _repository;
  final AuthBloc _authBloc;

  OwnerDashboardBloc({
    required OwnerDashboardRepository repository,
    required AuthBloc authBloc,
  })  : _repository = repository,
        _authBloc = authBloc,
        super(const OwnerDashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboardData>(_onRefreshDashboardData);
  }

  Future<void> _onLoadDashboardData(
      LoadDashboardData event,
      Emitter<OwnerDashboardState> emit,
      ) async {
    emit(const OwnerDashboardLoading());
    await _fetchDashboardData(emit);
  }

  Future<void> _onRefreshDashboardData(
      RefreshDashboardData event,
      Emitter<OwnerDashboardState> emit,
      ) async {
    // Don't show loading state on refresh (keeps UI stable)
    await _fetchDashboardData(emit);
  }

  Future<void> _fetchDashboardData(
      Emitter<OwnerDashboardState> emit) async {
    try {
      log.i('OwnerDashboardBloc: Fetching dashboard data...');

      // Get authenticated owner
      final authState = _authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final ownerId = authState.user.uid;

      // Get salon
      final salon = await _repository.getSalonForOwner(ownerId);
      if (salon == null) {
        throw Exception('No salon found for owner');
      }

      log.d('OwnerDashboardBloc: Found salon: ${salon.salonName}');

      // Calculate date ranges
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      // Fetch all required data in parallel for speed
      final next7Days = today.add(const Duration(days: 7));
      final results = await Future.wait([
        _repository.getAppointmentsForDate(salon.id, today),
        _repository.getNewClientsCount(salon.id, startOfWeek, endOfWeek),
        _repository.getAppointmentsForDateRange(salon.id, today, next7Days),
        _repository.getServicesForSalon(salon.id),
      ]);

      final todayAppointments = results[0] as List<AppointmentModel>;
      final newClientsCount = results[1] as int;
      final weekAppointments = results[2] as List<AppointmentModel>;
      final services = results[3] as List<ServiceModel>;

      // Calculate today's revenue (only completed/confirmed appointments)
      final todayRevenue = todayAppointments
          .where((app) =>
      app.status.toLowerCase() == 'completed' ||
          app.status.toLowerCase() == 'confirmed')
          .fold<double>(0.0, (sum, app) => sum + app.totalPrice);

      // Count today's appointments (exclude cancelled)
      final todayAppointmentsCount = todayAppointments
          .where((app) => app.status.toLowerCase() != 'cancelled')
          .length;

      // Get upcoming appointments for today (future only)
      final upcomingToday = todayAppointments
          .where((app) =>
      app.startTime.isAfter(now) &&
          app.status.toLowerCase() != 'cancelled')
          .toList();

      // Sort upcoming by start time
      upcomingToday.sort((a, b) => a.startTime.compareTo(b.startTime));

      // Get all upcoming appointments across the next 7 days
      final upcomingAll = weekAppointments
          .where((app) =>
      app.startTime.isAfter(now) &&
          app.status.toLowerCase() != 'cancelled' &&
          app.status.toLowerCase() != 'payment failed')
          .toList();
      upcomingAll.sort((a, b) => a.startTime.compareTo(b.startTime));

      // Calculate occupancy rate
      // Formula: (Total booked minutes / Total available minutes) * 100
      final occupancyRate = _calculateOccupancyRate(
        todayAppointments
            .where((app) => app.status.toLowerCase() != 'cancelled')
            .toList(),
        salon.openingTime ?? '08:00',
        salon.closingTime ?? '20:00',
      );

      final checklist = GoLiveChecklist.from(
        salon: salon,
        services: services,
      );

      log.i('OwnerDashboardBloc: Dashboard stats calculated successfully');
      log.d('Today Revenue: TSh ${todayRevenue.toStringAsFixed(0)}');
      log.d('Today Appointments: $todayAppointmentsCount');
      log.d('New Clients This Week: $newClientsCount');
      log.d('Occupancy Rate: ${occupancyRate.toStringAsFixed(1)}%');
      log.d('Upcoming Today: ${upcomingToday.length}');
      log.d(
        'Active services: ${services.where((s) => s.isActive).length}/${services.length}',
      );

      final stats = DashboardStats(
        todayRevenue: todayRevenue,
        todayAppointmentsCount: todayAppointmentsCount,
        newClientsThisWeek: newClientsCount,
        occupancyRate: occupancyRate,
        upcomingToday: upcomingToday.take(5).toList(), // Show max 5
        upcomingAll: upcomingAll.take(10).toList(), // Show max 10
        lastUpdated: DateTime.now(),
      );

      emit(OwnerDashboardLoaded(
        stats: stats,
        salonName: salon.salonName,
        checklist: checklist,
      ));
    } catch (e, s) {
      log.e('OwnerDashboardBloc: Error fetching dashboard data',
          error: e, stackTrace: s);
      emit(OwnerDashboardError('Failed to load dashboard: ${e.toString()}'));
    }
  }

  /// Calculates occupancy rate based on booked time vs available time
  double _calculateOccupancyRate(
      List<AppointmentModel> appointments,
      String openingTime,
      String closingTime,
      ) {
    try {
      // Parse opening/closing times
      final openingParts = openingTime.split(':');
      final closingParts = closingTime.split(':');

      final openingHour = int.parse(openingParts[0]);
      final openingMinute = int.parse(openingParts[1]);
      final closingHour = int.parse(closingParts[0]);
      final closingMinute = int.parse(closingParts[1]);

      // Calculate total available minutes
      final totalAvailableMinutes =
          (closingHour * 60 + closingMinute) - (openingHour * 60 + openingMinute);

      if (totalAvailableMinutes <= 0) return 0.0;

      // Calculate total booked minutes
      final totalBookedMinutes = appointments.fold<int>(
        0,
            (sum, app) => sum + app.durationMinutes,
      );

      // Calculate percentage
      final occupancyRate =
          (totalBookedMinutes / totalAvailableMinutes) * 100;

      // Cap at 100% (in case of overlapping appointments)
      return occupancyRate > 100 ? 100.0 : occupancyRate;
    } catch (e) {
      log.e('Error calculating occupancy rate', error: e);
      return 0.0;
    }
  }
}
