import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/app/services/in_app_review_service.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/shared/models/appointment_model.dart';

import '../../domain/repositories/appoitments_repository.dart';
import 'appoitment_events.dart';
import 'appoitments_state.dart';

class AppointmentsBloc extends Bloc<AppointmentsEvent, AppointmentsState> {
  final AppointmentsRepository _appointmentsRepository;
  final AuthBloc _authBloc;
  final InAppReviewService _inAppReviewService;

  AppointmentsBloc({
    required AppointmentsRepository appointmentsRepository,
    required AuthBloc authBloc,
  })  : _appointmentsRepository = appointmentsRepository,
        _authBloc = authBloc,
        _inAppReviewService = sl<InAppReviewService>(),
        super(AppointmentsInitial()) {
    on<FetchAppointmentsRequested>(_onFetchAppointmentsRequested);
  }

  Future<void> _onFetchAppointmentsRequested(
      FetchAppointmentsRequested event,
      Emitter<AppointmentsState> emit,
      ) async {
    emit(AppointmentsLoading());

    try {
      final authState = _authBloc.state;

      // Check for GuestMode first
      if (authState is GuestMode) {
        log.i('AppointmentsBloc: Guest user - returning empty list');
        emit(const AppointmentsLoaded(
          pendingPaymentAppointments: [],
          upcomingAppointments: [],
          pastAppointments: [],
        ));
        return;
      }

      // Check for authentication
      if (authState is! Authenticated) {
        log.w('AppointmentsBloc: User not authenticated');
        emit(const AppointmentsError(
            'Please sign in to view your appointments.'));
        return;
      }

      final userId = authState.user.uid;
      log.d('AppointmentsBloc: Fetching appointments for user: $userId');

      final allAppointments =
      await _appointmentsRepository.getAppointments(userId);
      log.d(
          'AppointmentsBloc: Fetched ${allAppointments.length} total appointments');

      final now = DateTime.now();

      //==========================================================================
      // FIXED: Proper categorization based on STATUS + TIME
      //==========================================================================

      // 1. PENDING PAYMENT: Status is 'Pending Payment' regardless of time
      //    These need user action (complete payment or will expire)
      final pendingPayment = allAppointments
          .where((app) => app.appointment.status == AppointmentStatus.pendingPayment)
          .toList();

      // 2. UPCOMING: Status is 'Confirmed' AND time is in the future
      //    These are paid and scheduled
      final upcoming = allAppointments
          .where((app) =>
      app.appointment.status == AppointmentStatus.confirmed &&
          app.appointment.startTime.isAfter(now))
          .toList();

      // 3. PAST: Either:
      //    - Status is 'Confirmed' but time has passed (should be auto-completed)
      //    - Status is 'Completed', 'Cancelled', 'No Show', 'Payment Failed'
      final past = allAppointments.where((app) {
        final appointment = app.appointment;
        final status = appointment.status;
        final isPastTime = appointment.startTime.isBefore(now);

        // Include if status is terminal (completed, cancelled, etc.)
        if (AppointmentStatus.terminal.contains(status)) {
          return true;
        }

        // Include confirmed appointments that are past their time
        if (status == AppointmentStatus.confirmed && isPastTime) {
          return true;
        }

        return false;
      }).toList();

      // Sort each list appropriately
      pendingPayment.sort(
              (a, b) => a.appointment.createdAt.compareTo(b.appointment.createdAt));
      upcoming.sort(
              (a, b) => a.appointment.startTime.compareTo(b.appointment.startTime));
      past.sort(
              (a, b) => b.appointment.startTime.compareTo(a.appointment.startTime));

      log.i(
          'AppointmentsBloc: Loaded ${pendingPayment.length} pending payment, '
              '${upcoming.length} upcoming, ${past.length} past appointments');

      emit(AppointmentsLoaded(
        pendingPaymentAppointments: pendingPayment,
        upcomingAppointments: upcoming,
        pastAppointments: past,
      ));

      // Trigger in-app review check based on completed appointment count
      final completedCount = past
          .where((a) => a.appointment.status == AppointmentStatus.completed)
          .length;
      if (completedCount > 0) {
        _inAppReviewService.onCompletedAppointmentsLoaded(completedCount);
      }
    } catch (e, s) {
      log.e('AppointmentsBloc: Error loading appointments',
          error: e, stackTrace: s);
      emit(AppointmentsError('Failed to load appointments: ${e.toString()}'));
    }
  }
}