import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/3_owner_management/staff/bloc/staff_event.dart';
import 'package:pendeza/features/3_owner_management/staff/bloc/staff_state.dart';

import '../domain/repository/staff_repository.dart';


class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final StaffRepository _staffRepository;
  final AuthBloc _authBloc;

  StaffBloc({
    required StaffRepository staffRepository,
    required AuthBloc authBloc,
  })  : _staffRepository = staffRepository,
        _authBloc = authBloc,
        super(StaffInitial()) {
    on<FetchStaffRequested>(_onFetchStaffRequested);
    on<AddStaffRequested>(_onAddStaffRequested);
    on<UpdateStaffRequested>(_onUpdateStaffRequested);
    on<DeleteStaffRequested>(_onDeleteStaffRequested);
  }

  Future<void> _onFetchStaffRequested(
      FetchStaffRequested event,
      Emitter<StaffState> emit,
      ) async {
    emit(StaffLoading());
    try {
      final salonId = await _getSalonId();
      final staff = await _staffRepository.getStaff(salonId);
      emit(StaffLoadSuccess(staff));
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  Future<void> _onAddStaffRequested(
      AddStaffRequested event,
      Emitter<StaffState> emit,
      ) async {
    emit(StaffOperationInProgress());
    try {
      final salonId = await _getSalonId();
      await _staffRepository.addStaff(event.staff.copyWith(salonId: salonId));
      emit(StaffOperationSuccess());
      add(FetchStaffRequested());
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  Future<void> _onUpdateStaffRequested(
      UpdateStaffRequested event,
      Emitter<StaffState> emit,
      ) async {
    emit(StaffOperationInProgress());
    try {
      await _staffRepository.updateStaff(event.staff);
      emit(StaffOperationSuccess());
      add(FetchStaffRequested());
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  Future<void> _onDeleteStaffRequested(
      DeleteStaffRequested event,
      Emitter<StaffState> emit,
      ) async {
    emit(StaffOperationInProgress());
    try {
      await _staffRepository.deleteStaff(event.staffId);
      emit(StaffOperationSuccess());
      add(FetchStaffRequested());
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  Future<String> _getSalonId() async {
    final authState = _authBloc.state;
    if (authState is Authenticated) {
      final ownerId = authState.user.uid;
      final salon = await _staffRepository.getSalonForOwner(ownerId);
      if (salon == null) {
        throw Exception("Error: Could not find a salon for the current owner.");
      }
      return salon.id;
    } else {
      throw Exception("Error: User is not authenticated.");
    }
  }
}
