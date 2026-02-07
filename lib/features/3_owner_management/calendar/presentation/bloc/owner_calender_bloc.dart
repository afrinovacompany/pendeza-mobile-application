import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_appointments/domain/repositories/appoitments_repository.dart'; // Use the updated repo
import 'package:pendeza/app/utils/logger.dart';
import 'package:table_calendar/table_calendar.dart'; // <-- 1. IMPORT THIS

import 'owner_calender_event.dart';
import 'owner_calender_state.dart';

class OwnerCalendarBloc extends Bloc<OwnerCalendarEvent, OwnerCalendarState> {
  // Use AppointmentsRepository as it now has the needed methods
  final AppointmentsRepository _appointmentsRepository =
  sl<AppointmentsRepository>();
  final AuthBloc _authBloc;

  String? _cachedSalonId; // Cache salon ID to avoid repeated lookups

  OwnerCalendarBloc({required AuthBloc authBloc})
      : _authBloc = authBloc,
        super(OwnerCalendarInitial()) {
    on<LoadAppointmentsForDate>(_onLoadAppointmentsForDate);
  }

  Future<void> _onLoadAppointmentsForDate(
      LoadAppointmentsForDate event,
      Emitter<OwnerCalendarState> emit,
      ) async {
    bool shouldShowLoading = true;

    // 2. FIX: Use isSameDay for date comparisons
    if (state is OwnerCalendarLoaded &&
        isSameDay((state as OwnerCalendarLoaded).selectedDate, event.date)) {
      shouldShowLoading = false; // Already loaded for this date, refresh silently
    } else if (state is OwnerCalendarError &&
        isSameDay((state as OwnerCalendarError).errorDate, event.date)) {
      shouldShowLoading = true; // Always show loading when retrying an error
    } else if (state is OwnerCalendarLoading &&
        isSameDay((state as OwnerCalendarLoading).loadingDate, event.date)) {
      return; // Already loading this date
    }

    if (shouldShowLoading) {
      emit(OwnerCalendarLoading(event.date));
    }

    try {
      // Get Salon ID (use cache or fetch)
      if (_cachedSalonId == null) {
        final authState = _authBloc.state;
        if (authState is Authenticated && authState.user.role == 'owner') {
          final ownerId = authState.user.uid;
          log.d("OwnerCalendarBloc: Fetching salon ID for owner $ownerId");
          final salon = await _appointmentsRepository.getSalonForOwner(ownerId);
          if (salon == null) {
            throw Exception('Salon not found for owner.');
          }
          _cachedSalonId = salon.id;
          log.d("OwnerCalendarBloc: Cached salon ID: $_cachedSalonId");
        } else {
          throw Exception('User is not an authenticated owner.');
        }
      }

      if (_cachedSalonId == null) {
        throw Exception('Could not retrieve Salon ID.');
      }

      // Fetch appointments using the correct function name
      final appointments =
      await _appointmentsRepository.getConfirmedAppointmentsForSalon(
        _cachedSalonId!,
        event.date,
      );

      emit(OwnerCalendarLoaded(appointments, event.date));
    } catch (e, s) {
      log.e("OwnerCalendarBloc: Error loading appointments for ${event.date}",
          error: e, stackTrace: s);
      emit(OwnerCalendarError(
          'Failed to load appointments: ${e.toString()}', event.date));
    }
  }
}