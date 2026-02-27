import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/shared/models/appointment_model.dart';

import '../../domain/models/regular_client.dart';
import '../../domain/repositories/client_management_repository_new.dart';
import 'client_management_event_new.dart';
import 'client_management_state_new.dart';

class ClientManagementBloc extends Bloc<ClientManagementEvent, ClientManagementState> {
  final ClientManagementRepository _repository;
  final FirestoreService _firestoreService;
  final AuthBloc _authBloc;
  String? _currentSalonId;

  ClientManagementBloc({
    required ClientManagementRepository repository,
    required FirestoreService firestoreService,
    required AuthBloc authBloc,
  })  : _repository = repository,
        _firestoreService = firestoreService,
        _authBloc = authBloc,
        super(const ClientManagementInitial()) {
    on<LoadClients>(_onLoadClients);
    on<SearchClients>(_onSearchClients);
    on<RefreshClients>(_onRefreshClients);
  }

  Future<void> _onLoadClients(
      LoadClients event,
      Emitter<ClientManagementState> emit,
      ) async {
    emit(const ClientManagementLoading());
    await _loadData(emit);
  }

  Future<void> _onSearchClients(
      SearchClients event,
      Emitter<ClientManagementState> emit,
      ) async {
    final currentState = state;

    // If not loaded yet, load first
    if (currentState is! ClientManagementLoaded) {
      await _loadData(emit);
      if (state is! ClientManagementLoaded) return;
    }

    final loadedState = state as ClientManagementLoaded;

    // Empty query = clear search
    if (event.query.trim().isEmpty) {
      emit(loadedState.copyWith(clearSearch: true));
      return;
    }

    try {
      final salonId = await _getSalonId();
      final results = await _repository.searchClients(salonId, event.query);

      emit(loadedState.copyWith(searchResults: results));
    } catch (e, s) {
      log.e('Error searching clients', error: e, stackTrace: s);
    }
  }

  Future<void> _onRefreshClients(
      RefreshClients event,
      Emitter<ClientManagementState> emit,
      ) async {
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<ClientManagementState> emit) async {
    try {
      log.i('Loading client management data');

      final salonId = await _getSalonId();

      // Fetch both in parallel — typed separately to avoid List<Object> issue
      final regularsFuture = _repository.getRegularClients(salonId);
      final bookingsFuture = _repository.getRecentBookings(salonId);

      final List<RegularClient> regulars = await regularsFuture;
      final List<AppointmentModel> bookings = await bookingsFuture;

      log.i('Loaded ${regulars.length} regulars, ${bookings.length} recent bookings');

      emit(ClientManagementLoaded(
        regularClients: regulars,
        recentBookings: bookings,
      ));
    } catch (e, s) {
      log.e('Error loading client data', error: e, stackTrace: s);
      emit(ClientManagementError('Failed to load clients: ${e.toString()}'));
    }
  }

  Future<String> _getSalonId() async {
    if (_currentSalonId != null) return _currentSalonId!;

    final authState = _authBloc.state;
    if (authState is! Authenticated) {
      throw Exception('User not authenticated');
    }

    final salon = await _firestoreService.getSalonForOwner(
      ownerId: authState.user.uid,
    );

    if (salon == null) {
      throw Exception('No salon found for owner');
    }

    _currentSalonId = salon.id;
    return salon.id;
  }
}