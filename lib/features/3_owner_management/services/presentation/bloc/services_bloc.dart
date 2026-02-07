import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/3_owner_management/services/domain/repositories/services_repository.dart';
import 'package:pendeza/app/utils/logger.dart'; // Import logger
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
    on<ToggleServiceActiveRequested>(_onToggleServiceActive);
    on<ToggleServiceFeaturedRequested>(_onToggleServiceFeatured);

    // Fetch services immediately when the BLoC is created
    add(FetchServicesRequested());
  }

  Future<void> _onFetchServicesRequested(
      FetchServicesRequested event,
      Emitter<ServicesState> emit,
      ) async {
    // FIX: Don't emit ServicesLoading if we are already loaded.
    // This prevents a full-screen loader on a simple refresh.
    if (state is! ServicesLoadSuccess) {
      emit(ServicesLoading());
    }
    try {
      log.i('Fetching services...');
      final salonId = await _getSalonId();
      final services = await _servicesRepository.getServices(salonId);
      emit(ServicesLoadSuccess(services));
    } catch (e, s) {
      log.e('Failed to fetch services', error: e, stackTrace: s);
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onAddServiceRequested(
      AddServiceRequested event,
      Emitter<ServicesState> emit,
      ) async {
    // FIX: Preserve the loaded list while the operation is in progress
    // This stops the UI from showing a full-screen loader
    final currentState = state;
    emit(ServiceOperationInProgress());
    try {
      log.i('Adding service: ${event.service.name}');
      final salonId = await _getSalonId();
      await _servicesRepository
          .addService(event.service.copyWith(salonId: salonId));
      emit(const ServiceOperationSuccess('Service added successfully'));
      add(FetchServicesRequested());
    } catch (e, s) {
      log.e('Failed to add service', error: e, stackTrace: s);
      // FIX: Go back to the previous state (the list) on failure
      if (currentState is ServicesLoadSuccess) {
        emit(currentState);
      }
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onUpdateServiceRequested(
      UpdateServiceRequested event,
      Emitter<ServicesState> emit,
      ) async {
    final currentState = state;
    emit(ServiceOperationInProgress());
    try {
      log.i('Updating service: ${event.service.id}');
      await _servicesRepository.updateService(event.service);
      emit(const ServiceOperationSuccess('Service updated successfully'));
      add(FetchServicesRequested());
    } catch (e, s) {
      log.e('Failed to update service', error: e, stackTrace: s);
      if (currentState is ServicesLoadSuccess) {
        emit(currentState);
      }
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onDeleteServiceRequested(
      DeleteServiceRequested event,
      Emitter<ServicesState> emit,
      ) async {
    final currentState = state;
    emit(ServiceOperationInProgress());
    try {
      log.i('Deleting service: ${event.serviceId}');
      await _servicesRepository.deleteService(event.serviceId);
      emit(const ServiceOperationSuccess('Service deleted successfully'));
      add(FetchServicesRequested());
    } catch (e, s) {
      log.e('Failed to delete service', error: e, stackTrace: s);
      if (currentState is ServicesLoadSuccess) {
        emit(currentState);
      }
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onToggleServiceActive(
      ToggleServiceActiveRequested event,
      Emitter<ServicesState> emit,
      ) async {
    final currentState = state;
    if (currentState is! ServicesLoadSuccess) return;

    try {
      // Find the service
      final service = currentState.services.firstWhere(
        (s) => s.id == event.serviceId,
      );
      final newStatus = !service.isActive;

      log.i('Toggling service active: ${event.serviceId} -> $newStatus');

      // Update locally first for immediate feedback
      final updatedServices = currentState.services.map((s) {
        if (s.id == event.serviceId) {
          return s.copyWith(isActive: newStatus);
        }
        return s;
      }).toList();
      emit(ServicesLoadSuccess(updatedServices));

      // Then update in database
      await _servicesRepository.updateService(service.copyWith(isActive: newStatus));
      emit(ServiceOperationSuccess(newStatus ? 'Service activated' : 'Service paused'));
    } catch (e, s) {
      log.e('Failed to toggle service', error: e, stackTrace: s);
      emit(currentState); // Revert to previous state
      emit(ServicesError(e.toString()));
    }
  }

  Future<void> _onToggleServiceFeatured(
      ToggleServiceFeaturedRequested event,
      Emitter<ServicesState> emit,
      ) async {
    final currentState = state;
    if (currentState is! ServicesLoadSuccess) return;

    try {
      final service = currentState.services.firstWhere(
        (s) => s.id == event.serviceId,
      );
      final newStatus = !service.isFeatured;

      log.i('Toggling service featured: ${event.serviceId} -> $newStatus');

      // Update locally first
      final updatedServices = currentState.services.map((s) {
        if (s.id == event.serviceId) {
          return s.copyWith(isFeatured: newStatus);
        }
        return s;
      }).toList();
      emit(ServicesLoadSuccess(updatedServices));

      // Then update in database
      await _servicesRepository.updateService(service.copyWith(isFeatured: newStatus));
      emit(ServiceOperationSuccess(
          newStatus ? 'Service marked as featured' : 'Service unfeatured'));
    } catch (e, s) {
      log.e('Failed to toggle featured', error: e, stackTrace: s);
      emit(currentState);
      emit(ServicesError(e.toString()));
    }
  }

  Future<String> _getSalonId() async {
    final authState = _authBloc.state;
    if (authState is Authenticated) {
      final ownerId = authState.user.uid;
      final salon = await _servicesRepository.getSalonForOwner(ownerId);
      if (salon == null) {
        log.e('No salon found for owner');
        throw Exception("Error: Could not find a salon for the current owner.");
      }
      return salon.id;
    } else {
      log.w('User is not authenticated');
      throw Exception("Error: User is not authenticated.");
    }
  }
}