import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import '../../domain/repositories/client_management_repository.dart';
import 'client_details_event.dart';
import 'client_details_state.dart';

class ClientDetailsBloc extends Bloc<ClientDetailsEvent, ClientDetailsState> {
  final ClientManagementRepository _repository;
  final FirestoreService _firestoreService;
  final AuthBloc _authBloc;
  String? _currentSalonId;
  String? _currentClientId;

  ClientDetailsBloc({
    required ClientManagementRepository repository,
    required FirestoreService firestoreService,
    required AuthBloc authBloc,
  })  : _repository = repository,
        _firestoreService = firestoreService,
        _authBloc = authBloc,
        super(const ClientDetailsInitial()) {
    on<LoadClientDetails>(_onLoadClientDetails);
    on<RefreshClientDetails>(_onRefreshClientDetails);
  }

  Future<void> _onLoadClientDetails(
      LoadClientDetails event,
      Emitter<ClientDetailsState> emit,
      ) async {
    _currentClientId = event.clientId;
    emit(const ClientDetailsLoading());
    await _fetchClientDetails(emit);
  }

  Future<void> _onRefreshClientDetails(
      RefreshClientDetails event,
      Emitter<ClientDetailsState> emit,
      ) async {
    // Don't show loading state, just refresh data
    await _fetchClientDetails(emit);
  }

  Future<void> _fetchClientDetails(Emitter<ClientDetailsState> emit) async {
    if (_currentClientId == null) {
      emit(const ClientDetailsError('No Client ID provided.'));
      return;
    }

    try {
      log.i('ClientDetailsBloc: Fetching details for client: $_currentClientId');

      // 1. Get Salon ID
      if (_currentSalonId == null) {
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
      }
      final salonId = _currentSalonId!;
      final clientId = _currentClientId!;

      // 2. Fetch all data in parallel
      final results = await Future.wait([
        _repository.getClientStats(salonId, clientId),
        _repository.getClientDetails(clientId),
        _repository.getClientAppointments(salonId, clientId),
      ]);

      // 3. Cast results
      final clientStats = results[0] as dynamic; // ClientStats
      final clientUser = results[1] as dynamic; // UserModel
      final appointments = results[2] as dynamic; // List<AppointmentModel>

      log.i('ClientDetailsBloc: Successfully fetched all details.');

      // 4. Emit loaded state
      emit(ClientDetailsLoaded(
        clientStats: clientStats,
        clientUser: clientUser,
        appointments: appointments,
      ));
    } catch (e, s) {
      log.e('ClientDetailsBloc: Error fetching client details',
          error: e, stackTrace: s);
      emit(ClientDetailsError('Failed to load client details: ${e.toString()}'));
    }
  }
}