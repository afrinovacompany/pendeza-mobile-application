
// --- Adjust these import paths to match your project structure ---



import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/app/utils/logger.dart';

import '../../domain/repositories/client_management_repository.dart';
import '../bloc/client_management_event.dart';
import '../bloc/client_management_state.dart';


class ClientManagementBloc
    extends Bloc<ClientManagementEvent, ClientManagementState> {
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
    await _fetchClients(emit, null);
  }

  Future<void> _onSearchClients(
      SearchClients event,
      Emitter<ClientManagementState> emit,
      ) async {
    await _fetchClients(emit, event.query);
  }

  Future<void> _onRefreshClients(
      RefreshClients event,
      Emitter<ClientManagementState> emit,
      ) async {
    // Keep current search query if exists
    final currentState = state;
    final query = currentState is ClientManagementLoaded
        ? currentState.searchQuery
        : null;
    await _fetchClients(emit, query);
  }

  Future<void> _fetchClients(
      Emitter<ClientManagementState> emit,
      String? searchQuery,
      ) async {
    try {
      log.i('ClientManagementBloc: Fetching clients...');

      // Get authenticated owner's salon
      final authState = _authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      // Get salon ID (cache it for future requests)
      if (_currentSalonId == null) {
        final salon = await _firestoreService.getSalonForOwner(
          ownerId: authState.user.uid,
        );
        if (salon == null) {
          throw Exception('No salon found for owner');
        }
        _currentSalonId = salon.id;
      }

      final salonId = _currentSalonId!;

      // Fetch or search clients
      final clients = searchQuery != null && searchQuery.isNotEmpty
          ? await _repository.searchClients(salonId, searchQuery)
          : await _repository.getAllClientsForSalon(salonId);

      log.i('ClientManagementBloc: Loaded ${clients.length} clients');

      emit(ClientManagementLoaded(
        clients: clients,
        searchQuery: searchQuery,
      ));
    } catch (e, s) {
      log.e('ClientManagementBloc: Error fetching clients',
          error: e, stackTrace: s);
      emit(ClientManagementError('Failed to load clients: ${e.toString()}'));
    }
  }
}

