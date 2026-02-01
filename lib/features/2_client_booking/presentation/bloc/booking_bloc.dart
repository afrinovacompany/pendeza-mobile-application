import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_booking/domain/repositories/booking_repository.dart';
import 'package:pendeza/shared/models/appointment_model.dart';

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
    on<FetchServicesForSalon>(_onFetchServicesForSalon);
    on<ServicesSelected>(_onServicesSelected);
    on<DateSelected>(_onDateSelected);
    on<FetchTimeSlots>(_onFetchTimeSlots);
    on<TimeSlotSelected>(_onTimeSlotSelected);
    on<ConfirmBooking>(_onConfirmBooking);
    on<ResetBooking>(_onResetBooking);
  }

  Future<void> _onStartBooking(
      StartBooking event,
      Emitter<BookingState> emit,
      ) async {
    log.i('BookingBloc: StartBooking event for Salon ID: ${event.salon.id}');

    final authState = _authBloc.state;
    log.d('BookingBloc: Auth state is ${authState.runtimeType}');

    // Allow guests to browse, but they'll be prompted at confirmation
    emit(BookingInProgress(
      salon: event.salon,
      status: BookingStatus.loadingServices,
      availableServices: const [],
      selectedServices: const [],
      availableTimeSlots: const [],
    ));

    add(FetchServicesForSalon());
  }

  Future<void> _onFetchServicesForSalon(
      FetchServicesForSalon event,
      Emitter<BookingState> emit,
      ) async {
    final currentState = state;
    if (currentState is! BookingInProgress) return;

    log.i('BookingBloc: Fetching services for Salon ID: ${currentState.salon.id}');

    try {
      final services = await _bookingRepository.getServicesForSalon(currentState.salon.id);
      log.i('BookingBloc: Fetched ${services.length} services.');

      emit(currentState.copyWith(
        status: BookingStatus.selectingServices,
        availableServices: services,
      ));
    } catch (e, s) {
      log.e('BookingBloc: Error fetching services', error: e, stackTrace: s);
      emit(BookingFailure(
        error: 'Failed to load services: ${e.toString()}',
        isGuestAttempt: false,
      ));
    }
  }

  void _onServicesSelected(
      ServicesSelected event,
      Emitter<BookingState> emit,
      ) {
    final currentState = state;
    if (currentState is! BookingInProgress) return;

    log.i('BookingBloc: ServicesSelected event with ${event.services.length} services.');

    emit(currentState.copyWith(
      status: BookingStatus.selectingTime,
      selectedServices: event.services,
    ));
  }

  Future<void> _onDateSelected(
      DateSelected event,
      Emitter<BookingState> emit,
      ) async {
    final currentState = state;
    if (currentState is! BookingInProgress) return;

    final formattedDate = DateFormat.yMd().format(event.date);
    log.i('BookingBloc: DateSelected event - Date: $formattedDate');

    emit(currentState.copyWith(
      selectedDate: event.date,
      selectedTimeSlot: null, // Clear previous selection
      availableTimeSlots: const [], // Clear while loading
    ));

    add(FetchTimeSlots());
  }

  Future<void> _onFetchTimeSlots(
      FetchTimeSlots event,
      Emitter<BookingState> emit,
      ) async {
    final currentState = state;
    if (currentState is! BookingInProgress) return;
    if (currentState.selectedDate == null) return;

    final date = currentState.selectedDate!;
    final formattedDate = DateFormat.yMd().format(date);
    log.i('BookingBloc: Generating time slots for $formattedDate...');

    try {
      // Get salon's opening hours
      final salon = currentState.salon;
      final openingTime = _parseTime(salon.openingTime);
      final closingTime = _parseTime(salon.closingTime);

      // Get total duration of selected services
      final totalDuration = currentState.selectedServices.fold<int>(
        0,
            (sum, service) => sum + service.durationMinutes,
      );

      // Generate base time slots (15-minute intervals)
      final baseSlots = _generateTimeSlots(
        openingTime: openingTime,
        closingTime: closingTime,
        intervalMinutes: 15,
        serviceDuration: totalDuration,
      );

      log.i('BookingBloc: Generated ${baseSlots.length} base slots.');

      // Fetch existing appointments for this date to filter out booked slots
      final existingAppointments = await _bookingRepository
          .getAppointmentsForSalonOnDate(salon.id, date);

      // Filter out slots that conflict with existing bookings
      final availableSlots = _filterBookedSlots(
        baseSlots: baseSlots,
        existingAppointments: existingAppointments,
        date: date,
        serviceDuration: totalDuration,
      );

      log.i('BookingBloc: ${availableSlots.length} slots available after filtering.');

      emit(currentState.copyWith(
        status: BookingStatus.selectingTime,
        availableTimeSlots: availableSlots,
      ));
    } catch (e, s) {
      log.e('BookingBloc: Error fetching time slots', error: e, stackTrace: s);
      emit(currentState.copyWith(
        status: BookingStatus.failure,
        errorMessage: 'Failed to load available times.',
      ));
    }
  }

  void _onTimeSlotSelected(
      TimeSlotSelected event,
      Emitter<BookingState> emit,
      ) {
    final currentState = state;
    if (currentState is! BookingInProgress) return;

    log.i('BookingBloc: TimeSlotSelected event - Time: ${event.timeSlot}');

    emit(currentState.copyWith(
      status: BookingStatus.reviewing,
      selectedTimeSlot: event.timeSlot,
    ));
  }

  Future<void> _onConfirmBooking(
      ConfirmBooking event,
      Emitter<BookingState> emit,
      ) async {
    final currentState = state;
    if (currentState is! BookingInProgress) return;

    log.i('BookingBloc: ConfirmBooking event initiated.');

    // Check authentication
    final authState = _authBloc.state;
    if (authState is GuestMode) {
      log.w('BookingBloc: Guest attempted to confirm booking');
      emit(BookingFailure(
        error: 'Please sign in to complete your booking.',
        isGuestAttempt: true,
      ));
      return;
    }

    if (authState is! Authenticated) {
      emit(const BookingFailure(
        error: 'You must be signed in to book an appointment.',
        isGuestAttempt: false,
      ));
      return;
    }

    log.i('BookingBloc: Processing booking...');
    emit(currentState.copyWith(status: BookingStatus.processing));

    try {
      // Validate required data
      if (currentState.selectedDate == null ||
          currentState.selectedTimeSlot == null ||
          currentState.selectedServices.isEmpty) {
        throw Exception('Missing booking details');
      }

      final clientId = authState.user.uid;
      log.d('BookingBloc: Client ID: $clientId');

      // Parse time slot to DateTime
      final timeSlot = currentState.selectedTimeSlot!;
      final parsedTime = DateFormat.jm().parse(timeSlot);
      final startTime = DateTime(
        currentState.selectedDate!.year,
        currentState.selectedDate!.month,
        currentState.selectedDate!.day,
        parsedTime.hour,
        parsedTime.minute,
      );
      log.d('BookingBloc: Calculated startTime: $startTime');

      // Calculate totals
      final totalDuration = currentState.selectedServices.fold<int>(
        0,
            (sum, service) => sum + service.durationMinutes,
      );
      final totalPrice = currentState.selectedServices.fold<double>(
        0.0,
            (sum, service) => sum + service.price,
      );

      //========================================================================
      // CRITICAL FIX: Create appointment with "Pending Payment" status
      //========================================================================
      final appointment = AppointmentModel(
        id: '', // Will be set by Firestore
        clientId: clientId,
        salonId: currentState.salon.id,
        staffId: null, // Optional
        serviceIds: currentState.selectedServices.map((s) => s.id).toList(),
        startTime: startTime,
        durationMinutes: totalDuration,
        totalPrice: totalPrice,
        status: AppointmentStatus.pendingPayment, // ← FIXED: Not "Confirmed"!
        createdAt: DateTime.now(),
      );

      log.d('BookingBloc: Created AppointmentModel: $appointment');

      // Save to Firestore and get the document ID
      final appointmentId = await _firestoreService.createAppointment(appointment);
      log.i('BookingBloc: Booking created with ID: $appointmentId. Emitting BookingPaymentRequired.');

      //========================================================================
      // Emit state to trigger payment flow
      //========================================================================
      emit(BookingPaymentRequired(
        appointmentId: appointmentId,
        amount: totalPrice,
        salon: currentState.salon,
        services: currentState.selectedServices,
        appointmentDateTime: startTime,
      ));

    } catch (e, s) {
      log.e('BookingBloc: Error confirming booking', error: e, stackTrace: s);
      emit(BookingFailure(
        error: 'Failed to create booking: ${e.toString()}',
        isGuestAttempt: false,
      ));
    }
  }

  void _onResetBooking(
      ResetBooking event,
      Emitter<BookingState> emit,
      ) {
    log.i('BookingBloc: ResetBooking event.');
    emit(BookingInitial());
  }

  //============================================================================
  // HELPER METHODS
  //============================================================================

  /// Parse time string like "08:00" to TimeOfDay-like structure
  ({int hour, int minute}) _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return (
    hour: int.tryParse(parts[0]) ?? 8,
    minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  /// Generate time slots between opening and closing time
  List<String> _generateTimeSlots({
    required ({int hour, int minute}) openingTime,
    required ({int hour, int minute}) closingTime,
    required int intervalMinutes,
    required int serviceDuration,
  }) {
    final slots = <String>[];

    var currentHour = openingTime.hour;
    var currentMinute = openingTime.minute;

    // Calculate last possible slot (must finish before closing)
    final closingMinutes = closingTime.hour * 60 + closingTime.minute;
    final lastSlotMinutes = closingMinutes - serviceDuration;

    while (true) {
      final currentMinutes = currentHour * 60 + currentMinute;

      if (currentMinutes > lastSlotMinutes) break;

      // Format as "8:00 AM", "8:15 AM", etc.
      final time = DateTime(2024, 1, 1, currentHour, currentMinute);
      final formatted = DateFormat.jm().format(time);
      slots.add(formatted);

      // Increment by interval
      currentMinute += intervalMinutes;
      if (currentMinute >= 60) {
        currentHour += currentMinute ~/ 60;
        currentMinute = currentMinute % 60;
      }
    }

    return slots;
  }

  /// Filter out time slots that conflict with existing bookings
  List<String> _filterBookedSlots({
    required List<String> baseSlots,
    required List<AppointmentModel> existingAppointments,
    required DateTime date,
    required int serviceDuration,
  }) {
    // Only consider confirmed appointments (not pending payment, cancelled, etc.)
    final confirmedAppointments = existingAppointments
        .where((a) => a.status == AppointmentStatus.confirmed)
        .toList();

    if (confirmedAppointments.isEmpty) {
      return baseSlots;
    }

    return baseSlots.where((slot) {
      final parsedTime = DateFormat.jm().parse(slot);
      final slotStart = DateTime(
        date.year,
        date.month,
        date.day,
        parsedTime.hour,
        parsedTime.minute,
      );
      final slotEnd = slotStart.add(Duration(minutes: serviceDuration));

      // Check if this slot conflicts with any existing appointment
      for (final existing in confirmedAppointments) {
        final existingEnd = existing.endTime;

        // Check for overlap
        final hasOverlap = slotStart.isBefore(existingEnd) &&
            slotEnd.isAfter(existing.startTime);

        if (hasOverlap) {
          return false; // Slot is not available
        }
      }

      return true; // Slot is available
    }).toList();
  }
}