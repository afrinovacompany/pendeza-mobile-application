import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_booking/domain/repositories/booking_repository.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';

import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _bookingRepository = sl<BookingRepository>();
  final FirestoreService _firestoreService = sl<FirestoreService>();
  final AuthBloc _authBloc;

  BookingBloc({required AuthBloc authBloc})
      : _authBloc = authBloc,
        super(BookingInitial()) {
    on<StartBooking>(_onStartBooking);
    on<StartBookingWithId>(_onStartBookingWithId); // ✅ Handler for ID start
    on<FetchServicesForSalon>(_onFetchServicesForSalon);
    on<ServicesSelected>(_onServicesSelected);
    on<DateSelected>(_onDateSelected);
    on<FetchTimeSlots>(_onFetchTimeSlots);
    on<TimeSlotSelected>(_onTimeSlotSelected);
    on<ConfirmBooking>(_onConfirmBooking);
    on<ResetBooking>(_onResetBooking);
    on<PaymentCompleted>(_onPaymentCompleted);
    on<PaymentFailed>(_onPaymentFailed);
  }

  void _onStartBooking(StartBooking event, Emitter<BookingState> emit) {
    emit(BookingInProgress(
      salon: event.salon,
      status: BookingStatus.selectingServices,
      availableServices: const [],
      selectedServices: const [],
      availableTimeSlots: const [],
    ));
    add(FetchServicesForSalon());
  }

  // ✅ New Handler: Fetches the salon details first if only ID is provided
  Future<void> _onStartBookingWithId(StartBookingWithId event, Emitter<BookingState> emit) async {
    try {
      // Fetch full salon model using the ID
      final SalonModel salon = await _bookingRepository.getSalonDetails(event.salonId);
      // Trigger the standard start booking flow with the fetched model
      add(StartBooking(salon));
    } catch (e) {
      emit(BookingFailure(error: "Could not load salon details: $e"));
    }
  }

  Future<void> _onFetchServicesForSalon(FetchServicesForSalon event, Emitter<BookingState> emit) async {
    if (state is! BookingInProgress) return;
    final currentState = state as BookingInProgress;

    emit(currentState.copyWith(status: BookingStatus.loadingServices));

    try {
      final services = await _bookingRepository.getServicesForSalon(currentState.salon.id);
      emit(currentState.copyWith(
        status: BookingStatus.selectingServices,
        availableServices: services,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        status: BookingStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onServicesSelected(ServicesSelected event, Emitter<BookingState> emit) {
    if (state is! BookingInProgress) return;
    final currentState = state as BookingInProgress;
    emit(currentState.copyWith(selectedServices: event.services));
  }

  void _onDateSelected(DateSelected event, Emitter<BookingState> emit) {
    if (state is! BookingInProgress) return;
    final currentState = state as BookingInProgress;
    emit(currentState.copyWith(selectedDate: event.date));
    add(FetchTimeSlots());
  }

  Future<void> _onFetchTimeSlots(FetchTimeSlots event, Emitter<BookingState> emit) async {
    if (state is! BookingInProgress) return;
    final currentState = state as BookingInProgress;
    if (currentState.selectedDate == null) return;

    emit(currentState.copyWith(status: BookingStatus.processing));

    try {
      final appointments = await _bookingRepository.getAppointmentsForSalonOnDate(
        currentState.salon.id,
        currentState.selectedDate!,
      );

      final availableSlots = _generateTimeSlots(
        openingTime: currentState.salon.openingTime ?? '08:00',
        closingTime: currentState.salon.closingTime ?? '20:00',
        interval: 30,
      );

      // ✅ Uses the 'totalDurationMinutes' implicitly here via fold, matching getter logic
      final int totalDuration = currentState.selectedServices.fold(0, (sum, s) => sum + s.durationMinutes);

      var filteredSlots = _filterBookedSlots(
        baseSlots: availableSlots,
        existingAppointments: appointments,
        date: currentState.selectedDate!,
        serviceDuration: totalDuration,
      );

      // Filter out past time slots if the selected date is today
      filteredSlots = _filterPastSlots(
        slots: filteredSlots,
        date: currentState.selectedDate!,
      );

      emit(currentState.copyWith(
        status: BookingStatus.selectingTime,
        availableTimeSlots: filteredSlots,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        status: BookingStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onTimeSlotSelected(TimeSlotSelected event, Emitter<BookingState> emit) {
    if (state is! BookingInProgress) return;
    final currentState = state as BookingInProgress;
    emit(currentState.copyWith(selectedTimeSlot: event.timeSlot));
  }

  Future<void> _onConfirmBooking(ConfirmBooking event, Emitter<BookingState> emit) async {
    if (state is! BookingInProgress) return;
    final currentState = state as BookingInProgress;

    // Validate we have all required data
    if (currentState.selectedDate == null || currentState.selectedTimeSlot == null) {
      emit(BookingFailure(error: 'Please select a date and time slot.'));
      return;
    }
    if (currentState.selectedServices.isEmpty) {
      emit(BookingFailure(error: 'Please select at least one service.'));
      return;
    }

    emit(currentState.copyWith(status: BookingStatus.processing));

    try {
      // Parse the selected time slot into a full DateTime
      DateTime parsedTime;
      try {
        parsedTime = DateFormat('HH:mm').parse(currentState.selectedTimeSlot!);
      } catch (_) {
        parsedTime = DateFormat.jm().parse(currentState.selectedTimeSlot!);
      }

      final appointmentDateTime = DateTime(
        currentState.selectedDate!.year,
        currentState.selectedDate!.month,
        currentState.selectedDate!.day,
        parsedTime.hour,
        parsedTime.minute,
      );

      // Get current user ID from AuthBloc
      final authState = _authBloc.state;
      if (authState is! Authenticated) {
        emit(BookingFailure(error: 'You must be logged in to book.', isGuestAttempt: authState is GuestMode));
        return;
      }
      final clientId = authState.user.uid;

      // Create the appointment
      final appointment = AppointmentModel(
        id: '', // Firestore will generate
        clientId: clientId,
        salonId: currentState.salon.id,
        serviceIds: currentState.selectedServices.map((s) => s.id).toList(),
        startTime: appointmentDateTime,
        durationMinutes: currentState.totalDurationMinutes,
        totalPrice: currentState.totalPrice,
        status: AppointmentStatus.pendingPayment,
        createdAt: DateTime.now(),
      );

      final appointmentId = await _bookingRepository.createAppointment(appointment);

      emit(BookingPaymentRequired(
        appointmentId: appointmentId,
        amount: currentState.totalPrice,
        salon: currentState.salon,
        services: currentState.selectedServices,
        appointmentDateTime: appointmentDateTime,
      ));
    } catch (e) {
      log.e('ConfirmBooking error: $e');
      emit(BookingFailure(error: 'Failed to create booking: $e'));
    }
  }

  void _onResetBooking(ResetBooking event, Emitter<BookingState> emit) => emit(BookingInitial());

  void _onPaymentCompleted(PaymentCompleted event, Emitter<BookingState> emit) {
    emit(BookingSuccess(appointmentId: event.appointmentId));
  }

  void _onPaymentFailed(PaymentFailed event, Emitter<BookingState> emit) {
    emit(BookingFailure(error: event.reason ?? 'Payment failed'));
  }

  // --- HELPERS ---

  List<String> _generateTimeSlots({required String openingTime, required String closingTime, int interval = 30}) {
    List<String> slots = [];
    DateFormat format = DateFormat("HH:mm");

    try {
      DateTime open = format.parse(openingTime);
      DateTime close = format.parse(closingTime);

      // Handle case where closing time is early morning next day (e.g., 01:00)
      if (close.isBefore(open)) {
        close = close.add(const Duration(days: 1));
      }

      DateTime current = open;
      while (current.isBefore(close)) {
        slots.add(format.format(current));
        current = current.add(Duration(minutes: interval));
      }
    } catch (e) {
      log.e("Error parsing time slots: $e");
    }
    return slots;
  }

  List<String> _filterBookedSlots({
    required List<String> baseSlots,
    required List<AppointmentModel> existingAppointments,
    required DateTime date,
    required int serviceDuration,
  }) {
    final confirmedAppointments = existingAppointments
        .where((a) => a.status == AppointmentStatus.confirmed)
        .toList();

    if (confirmedAppointments.isEmpty) return baseSlots;

    return baseSlots.where((slot) {
      try {
        final parsedTime = DateFormat("HH:mm").parse(slot);
        final slotStart = DateTime(
          date.year, date.month, date.day, parsedTime.hour, parsedTime.minute,
        );
        final slotEnd = slotStart.add(Duration(minutes: serviceDuration));

        for (final existing in confirmedAppointments) {
          // Assuming appointment model has startTime and endTime as DateTime
          // If not, they would need parsing here too
          final existingStart = existing.startTime;
          final existingEnd = existing.endTime;

          final hasOverlap = slotStart.isBefore(existingEnd) && slotEnd.isAfter(existingStart);
          if (hasOverlap) return false;
        }
        return true;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Removes time slots that have already passed when [date] is today.
  /// Adds a 15-minute buffer so users can't book a slot starting in 5 minutes.
  List<String> _filterPastSlots({
    required List<String> slots,
    required DateTime date,
  }) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    if (!isToday) return slots;

    final bufferMinutes = 15;
    final cutoff = now.add(Duration(minutes: bufferMinutes));

    return slots.where((slot) {
      try {
        final parsed = DateFormat('HH:mm').parse(slot);
        final slotTime = DateTime(
          date.year, date.month, date.day, parsed.hour, parsed.minute,
        );
        return slotTime.isAfter(cutoff);
      } catch (_) {
        return false;
      }
    }).toList();
  }
}