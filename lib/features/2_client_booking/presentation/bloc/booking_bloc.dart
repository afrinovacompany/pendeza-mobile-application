import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/2_client_booking/domain/repositories/booking_repository.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _bookingRepository = sl<BookingRepository>();

  BookingBloc() : super(const BookingInitial()) {
    on<StartBooking>(_onStartBooking);
    on<FetchServicesForSalon>(_onFetchServicesForSalon);
    on<SelectServices>(_onSelectServices);
    on<SelectStaff>(_onSelectStaff);
    on<SelectDateTime>(_onSelectDateTime);
    on<ConfirmBooking>(_onConfirmBooking);
  }

  void _onStartBooking(StartBooking event, Emitter<BookingState> emit) {
    emit(BookingInProgress(salon: event.salon));
    // Immediately fetch services when booking starts
    add(FetchServicesForSalon());
  }

  Future<void> _onFetchServicesForSalon(
      FetchServicesForSalon event, Emitter<BookingState> emit) async {
    if (state is BookingInProgress) {
      final currentState = state as BookingInProgress;
      // Show that services are loading
      emit(currentState.copyWith(status: BookingStatus.loadingServices));
      try {
        final services =
        await _bookingRepository.getServicesForSalon(currentState.salon.id);
        emit(currentState.copyWith(
          availableServices: services,
          status: BookingStatus.inProgress, // Revert to inProgress after loading
        ));
      } catch (e) {
        emit(BookingFailure(e.toString()));
      }
    }
  }

  void _onSelectServices(SelectServices event, Emitter<BookingState> emit) {
    if (state is BookingInProgress) {
      final currentState = state as BookingInProgress;
      emit(currentState.copyWith(selectedServices: event.services));
    }
  }

  void _onSelectStaff(SelectStaff event, Emitter<BookingState> emit) {
    if (state is BookingInProgress) {
      final currentState = state as BookingInProgress;
      emit(currentState.copyWith(selectedStaff: event.staff));
    }
  }

  void _onSelectDateTime(SelectDateTime event, Emitter<BookingState> emit) {
    if (state is BookingInProgress) {
      final currentState = state as BookingInProgress;
      emit(currentState.copyWith(selectedDateTime: event.dateTime));
    }
  }

  void _onConfirmBooking(
      ConfirmBooking event, Emitter<BookingState> emit) async {
    if (state is BookingInProgress) {
      final currentState = state as BookingInProgress;
      emit(currentState.copyWith(status: BookingStatus.loading));
      try {
        // In a real app, you'd call a repository to save the booking.
        await Future.delayed(const Duration(seconds: 2)); // Simulate network call
        emit(const BookingSuccess());
      } catch (e) {
        emit(BookingFailure(e.toString()));
      }
    }
  }
}
