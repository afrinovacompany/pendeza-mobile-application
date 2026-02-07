// lib/features/3_owner_management/presentation/bloc/analytics_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';

import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/models/service_model.dart';

import '../../../3_owner_management/dashboard/domain/repositories/owner_dashboard_repository.dart';
import 'analytic_event.dart';
import 'analytic_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final OwnerDashboardRepository _repository;
  final AuthBloc _authBloc;

  AnalyticsBloc({
    required OwnerDashboardRepository repository,
    required AuthBloc authBloc,
  })  : _repository = repository,
        _authBloc = authBloc,
        super(const AnalyticsInitial()) {
    on<LoadAnalyticsData>(_onLoadAnalyticsData);
    on<RefreshAnalyticsData>(_onRefreshAnalyticsData);
  }

  Future<void> _onLoadAnalyticsData(LoadAnalyticsData event, Emitter<AnalyticsState> emit) async {
    emit(const AnalyticsLoading());
    await _fetchAnalytics(emit);
  }

  Future<void> _onRefreshAnalyticsData(RefreshAnalyticsData event, Emitter<AnalyticsState> emit) async {
    await _fetchAnalytics(emit);
  }

  Future<void> _fetchAnalytics(Emitter<AnalyticsState> emit) async {
    try {
      log.i('AnalyticsBloc: Fetching analytics data...');

      final authState = _authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final ownerId = authState.user.uid;
      final salon = await _repository.getSalonForOwner(ownerId);
      if (salon == null) {
        throw Exception('No salon found');
      }

      // Fetch last 30 days appointments (for service popularity)
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final appointments = await _repository.getAppointmentsForDateRange(salon.id, thirtyDaysAgo, now);

      // Fetch services
      final services = await _repository.getServicesForSalon(salon.id); // Assuming we add this method to repo

      // Process weekly revenue (last 7 days, Mon-Sun)
      final weeklyRevenue = _calculateWeeklyRevenue(appointments);

      // Process service popularity (last 30 days)
      // FIX: Pass salon.id to be used in the fallback ServiceModel constructor
      final servicePopularity = _calculateServicePopularity(appointments, services, salon.id);

      // Top services (sorted by count)
      final topServices = servicePopularity.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      emit(AnalyticsLoaded(
        weeklyRevenue: weeklyRevenue,
        servicePopularity: servicePopularity,
        topServices: topServices,
      ));
    } catch (e, s) {
      log.e('AnalyticsBloc: Error fetching data', error: e, stackTrace: s);
      emit(AnalyticsError('Failed to load analytics: ${e.toString()}'));
    }
  }

  List<double> _calculateWeeklyRevenue(List<AppointmentModel> appointments) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1)); // Start of week (Mon)
    final weeklyRevenue = List<double>.filled(7, 0.0);

    for (final app in appointments.where((a) => a.status == 'Confirmed' && a.startTime.isAfter(monday))) {
      final dayIndex = app.startTime.weekday - 1; // 0=Mon
      weeklyRevenue[dayIndex] += app.totalPrice;
    }

    return weeklyRevenue;
  }

  // FIX: Added salonId parameter
  Map<String, int> _calculateServicePopularity(
      List<AppointmentModel> appointments,
      List<ServiceModel> services,
      String salonId, // Added salonId
      ) {
    final popularity = <String, int>{};

    for (final app in appointments.where((a) => a.status == 'Confirmed')) {
      for (final serviceId in app.serviceIds) {
        popularity[serviceId] = (popularity[serviceId] ?? 0) + 1;
      }
    }

    // Map IDs to names
    final namedPopularity = <String, int>{};
    for (final entry in popularity.entries) {
      final service = services.firstWhere(
            (s) => s.id == entry.key,
        // FIX: Provide all required arguments for the fallback ServiceModel
        orElse: () => ServiceModel(
          id: entry.key,
          salonId: salonId, // Added
          name: 'Unknown',
          category: 'Unknown', // Added
          price: 0,
          durationMinutes: 0,
        ),
      );
      namedPopularity[service.name] = entry.value;
    }

    return namedPopularity;
  }
}