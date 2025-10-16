import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/3_owner_management/services/domain/repositories/services_repository.dart';
import 'services_event.dart';
import 'services_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final ServicesRepository _servicesRepository;
  final AuthBloc _authBloc;

  ServicesBloc({
    required ServicesRepository servicesRepository,
    required AuthBloc authBloc,
  })  : _servicesRepository = servicesRepository,
        _authBloc = authBloc,
        super(ServicesInitial()) {
    on<FetchServicesRequested>(_onFetchServicesRequested);
    on<AddServiceRequested>(_onAddServiceRequested);
    on<UpdateServiceRequested>(_onUpdateServiceRequested);
    on<DeleteServiceRequested>(_onDeleteServiceRequested);
  }

  Future<void> _onFetchServicesRequested(
      FetchServicesRequested event,
      Emitter<ServicesState> emit,
      ) async {
    emit(ServicesLoading());
    try {
      final salonId = await _getSalonId();
      final services = await _servicesRepository.getServices(salonId);
      // FIX: Use the correct state name: ServicesLoadSuccess
      emit(ServicesLoadSuccess(services));
    } catch (e) {
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onAddServiceRequested(
      AddServiceRequested event,
      Emitter<ServicesState> emit,
      ) async {
    emit(ServiceOperationInProgress());
    try {
      final salonId = await _getSalonId();
      await _servicesRepository
          .addService(event.service.copyWith(salonId: salonId));
      emit(ServiceOperationSuccess());
      add(FetchServicesRequested());
    } catch (e) {
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onUpdateServiceRequested(
      UpdateServiceRequested event,
      Emitter<ServicesState> emit,
      ) async {
    emit(ServiceOperationInProgress());
    try {
      await _servicesRepository.updateService(event.service);
      emit(ServiceOperationSuccess());
      add(FetchServicesRequested());
    } catch (e) {
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onDeleteServiceRequested(
      DeleteServiceRequested event,
      Emitter<ServicesState> emit,
      ) async {
    emit(ServiceOperationInProgress());
    try {
      await _servicesRepository.deleteService(event.serviceId);
      emit(ServiceOperationSuccess());
      add(FetchServicesRequested());
    } catch (e) {
      emit(ServicesError(e.toString()));
    }
  }

  Future<String> _getSalonId() async {
    final authState = _authBloc.state;
    if (authState is Authenticated) {
      final ownerId = authState.user.uid;
      final salon = await _servicesRepository.getSalonForOwner(ownerId);
      if (salon == null) {
        throw Exception("Error: Could not find a salon for the current owner.");
      }
      return salon.id;
    } else {
      throw Exception("Error: User is not authenticated.");
    }
  }
}

