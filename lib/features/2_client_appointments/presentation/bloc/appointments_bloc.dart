import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';

import '../../domain/repositories/appoitments_repository.dart';
import 'appoitment_events.dart';
import 'appoitments_state.dart';



class AppointmentsBloc extends Bloc<AppointmentsEvent, AppointmentsState> {
  final AppointmentsRepository _appointmentsRepository;
  final AuthBloc _authBloc;

  AppointmentsBloc({
    required AppointmentsRepository appointmentsRepository,
    required AuthBloc authBloc,
  })  : _appointmentsRepository = appointmentsRepository,
        _authBloc = authBloc,
        super(AppointmentsInitial()) {
    on<FetchAppointmentsRequested>(_onFetchAppointmentsRequested);
  }

  Future<void> _onFetchAppointmentsRequested(
      FetchAppointmentsRequested event,
      Emitter<AppointmentsState> emit,
      ) async {
    emit(AppointmentsLoading());
    try {
      final userId = (_authBloc.state as dynamic).user.uid;
      if (userId == null) {
        emit(const AppointmentsError('User not authenticated.'));
        return;
      }

      final allAppointments = await _appointmentsRepository.getAppointments(userId);

      // Separate appointments into upcoming and past
      final now = DateTime.now();
      final upcoming = allAppointments
          .where((app) => app.appointment.startTime.isAfter(now))
          .toList();
      final past = allAppointments
          .where((app) => !app.appointment.startTime.isAfter(now))
          .toList();

      // Sort them for better presentation
      upcoming.sort((a, b) => a.appointment.startTime.compareTo(b.appointment.startTime));
      past.sort((a, b) => b.appointment.startTime.compareTo(a.appointment.startTime));


      emit(AppointmentsLoaded(
        upcomingAppointments: upcoming,
        pastAppointments: past,
      ));
    } catch (e) {
      emit(AppointmentsError('Failed to load appointments: ${e.toString()}'));
    }
  }
}
