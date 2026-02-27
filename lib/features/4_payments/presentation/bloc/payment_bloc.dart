import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pendeza/app/utils/logger.dart';
import '../../../../app/services/payment_service.dart';
import '../../../../app/services/service_locator.dart';
import 'payment_event.dart';
import 'payment_state.dart';

/// 🔥 REFACTORED PaymentBloc - Snippe Integration
///
/// **Changes for Snippe migration:**
/// ✅ Handles cases where transaction doc might not be created
/// ✅ Better null safety for transaction IDs
/// ✅ Improved status mapping
/// ✅ Added validation before watching documents
/// ✅ More defensive error handling
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentService _paymentService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream subscriptions for listening to status changes
  StreamSubscription<DocumentSnapshot>? _transactionSubscription;
  StreamSubscription<DocumentSnapshot>? _appointmentSubscription;

  PaymentBloc()
      : _paymentService = sl<PaymentService>(),
        super(PaymentInitial()) {
    on<InitiatePayment>(_onInitiatePayment);
    on<WatchPaymentStatus>(_onWatchPaymentStatus);
    on<_PaymentStatusChanged>(_onPaymentStatusChanged);
    on<CancelPaymentWatch>(_onCancelPaymentWatch);
    on<ResetPaymentState>(_onResetPaymentState);
  }

  /// Initiate payment with Snippe
  Future<void> _onInitiatePayment(
      InitiatePayment event,
      Emitter<PaymentState> emit,
      ) async {
    try {
      log.i('PaymentBloc: Initiating payment for appointment ${event.appointmentId}');
      emit(PaymentLoading());

      // 🔥 Call Snippe API via payment service
      final result = await _paymentService.initiatePayment(
        phoneNumber: event.phoneNumber,
        amount: event.amount,
        orderId: event.appointmentId,
        name: event.customerName,
        email: event.customerEmail,
        userId: event.userId, // 🔥 CRITICAL: Pass userId for Firestore rules
      );

      log.d('PaymentBloc: Payment result: $result');

      if (result['success'] == true) {
        log.i('✅ PaymentBloc: Payment initiated successfully');

        // 🔥 FIX: Safely extract transaction ID (might be null if userId was empty)
        final transactionId = result['transactionId'] as String?;

        // Show user feedback immediately
        emit(const PaymentInitiated(
          "Payment request sent! Complete payment on your phone.",
        ));

        // 🔥 FIX: Always watch appointment, optionally watch transaction
        // This handles cases where transaction doc wasn't created
        log.i('👂 Starting to watch payment status');
        add(WatchPaymentStatus(
          transactionId: transactionId, // May be null, that's OK
          appointmentId: event.appointmentId,
        ));
      } else {
        final errorMsg = result['message'] ?? 'Payment initiation failed';
        log.e('❌ PaymentBloc: Payment failed - $errorMsg');
        emit(PaymentError(errorMsg));
      }
    } catch (e, stackTrace) {
      log.e('PaymentBloc: Exception during payment', error: e, stackTrace: stackTrace);
      emit(PaymentError('Failed to initiate payment: ${e.toString()}'));
    }
  }

  /// Watch transaction AND appointment documents for status changes (REACTIVE)
  ///
  /// Uses DUAL LISTENER strategy:
  /// 1. Transaction listener - catches Snippe webhook updates (OPTIONAL - may not exist)
  /// 2. Appointment listener - catches updates to appointment status (REQUIRED)
  Future<void> _onWatchPaymentStatus(
      WatchPaymentStatus event,
      Emitter<PaymentState> emit,
      ) async {
    try {
      log.i('👂 Setting up payment status listeners');
      log.i('   Transaction ID: ${event.transactionId ?? "none"}');
      log.i('   Appointment ID: ${event.appointmentId}');

      // Cancel any existing subscriptions
      await _cancelSubscriptions();

      // ========================================
      // LISTENER 1: Transaction Document (OPTIONAL)
      // ========================================
      // 🔥 FIX: Only set up if transaction ID exists and is valid
      if (event.transactionId != null &&
          event.transactionId!.isNotEmpty &&
          event.transactionId != 'null') {

        log.i('👂 Setting up transaction listener: ${event.transactionId}');

        // 🔥 FIX: First check if document exists before subscribing
        final docExists = await _firestore
            .collection('transactions')
            .doc(event.transactionId)
            .get()
            .then((doc) => doc.exists)
            .catchError((e) {
          log.w('⚠️ Could not check transaction doc existence: $e');
          return false;
        });

        if (docExists) {
          _transactionSubscription = _firestore
              .collection('transactions')
              .doc(event.transactionId)
              .snapshots()
              .listen(
                (snapshot) {
              if (!snapshot.exists) {
                log.w('⚠️ Transaction document was deleted: ${event.transactionId}');
                return;
              }

              final data = snapshot.data();
              if (data == null) return;

              final status = data['status']?.toString().toLowerCase() ?? 'pending';
              log.d('📡 Transaction status update: $status');

              // Only emit for terminal states
              if (_isTerminalStatus(status)) {
                add(_PaymentStatusChanged(
                  status: status,
                  transactionId: event.transactionId!,
                  appointmentId: event.appointmentId,
                  data: data,
                  source: 'transaction',
                ));
              }
            },
            onError: (error) {
              log.e('❌ Error listening to transaction status', error: error);
              // Don't fail completely - appointment listener is primary
            },
          );
        } else {
          log.w('⚠️ Transaction document does not exist: ${event.transactionId}');
          log.i('   Relying on appointment listener only');
        }
      } else {
        log.i('ℹ️ No transaction ID provided, relying on appointment listener only');
      }

      // ========================================
      // LISTENER 2: Appointment Document (REQUIRED)
      // ========================================
      log.i('👂 Setting up appointment listener: ${event.appointmentId}');

      _appointmentSubscription = _firestore
          .collection('appointments')
          .doc(event.appointmentId)
          .snapshots()
          .listen(
            (snapshot) {
          if (!snapshot.exists) {
            log.w('⚠️ Appointment document does not exist: ${event.appointmentId}');
            return;
          }

          final data = snapshot.data();
          if (data == null) return;

          final status = data['status']?.toString() ?? 'Pending Payment';
          log.d('📡 Appointment status update: $status');

          // 🔥 FIX: Improved status mapping
          final paymentStatus = _mapAppointmentStatusToPaymentStatus(status);

          add(_PaymentStatusChanged(
            status: paymentStatus,
            transactionId: event.transactionId ?? '',
            appointmentId: event.appointmentId,
            data: data,
            source: 'appointment',
          ));
        },
        onError: (error) {
          log.e('❌ Error listening to appointment status', error: error);
          // This is critical - emit error if appointment listener fails
          emit(PaymentError('Failed to track payment status: ${error.toString()}'));
        },
      );

      log.i('✅ Payment status listeners set up successfully');
    } catch (e, stackTrace) {
      log.e('❌ Error setting up status listeners', error: e, stackTrace: stackTrace);
      emit(PaymentError('Failed to track payment status: ${e.toString()}'));
    }
  }

  /// Handle status changes from Firestore listeners
  Future<void> _onPaymentStatusChanged(
      _PaymentStatusChanged event,
      Emitter<PaymentState> emit,
      ) async {
    log.i('🔄 Processing status change from ${event.source}: ${event.status}');

    switch (event.status) {
      case 'completed':
      case 'success':
      case 'successful':
        log.i('✅ Payment COMPLETED! (from ${event.source})');
        await _cancelSubscriptions();
        emit(PaymentSuccess(event.appointmentId));
        break;

      case 'failed':
      case 'declined':
      case 'rejected':
        log.w('❌ Payment FAILED (from ${event.source})');
        await _cancelSubscriptions();
        final errorMsg = event.data['errorMessage'] ??
            event.data['failureReason'] ??
            event.data['error_message'] ??
            'Payment failed';
        emit(PaymentError(errorMsg.toString()));
        break;

      case 'processing':
      case 'initiated':
        log.i('⏳ Payment is being processed...');
        emit(const PaymentInitiated(
          "Processing payment... This may take a moment.",
        ));
        break;

      case 'pending':
        log.d('⏳ Payment still pending...');
        // Don't emit - just log
        break;

      case 'cancelled':
      case 'canceled':
        log.w('🚫 Payment cancelled');
        await _cancelSubscriptions();
        emit(const PaymentError('Payment was cancelled'));
        break;

      case 'expired':
        log.w('⏰ Payment expired');
        await _cancelSubscriptions();
        emit(const PaymentError('Payment request expired. Please try again.'));
        break;

      case 'error':
        log.e('❌ Payment tracking error');
        await _cancelSubscriptions();
        emit(const PaymentError(
          'Error tracking payment. Please check your booking status.',
        ));
        break;

      default:
        log.w('⚠️ Unknown payment status: ${event.status}');
    // Don't emit - unknown statuses shouldn't change UI state
    }
  }

  /// Cancel the status listeners
  Future<void> _onCancelPaymentWatch(
      CancelPaymentWatch event,
      Emitter<PaymentState> emit,
      ) async {
    log.i('🛑 Cancelling payment status listeners');
    await _cancelSubscriptions();
  }

  /// Reset payment state
  Future<void> _onResetPaymentState(
      ResetPaymentState event,
      Emitter<PaymentState> emit,
      ) async {
    log.i('🔄 Resetting payment state');
    await _cancelSubscriptions();
    emit(PaymentInitial());
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================

  /// Map appointment status to payment status
  /// 🔥 FIX: More comprehensive mapping
  String _mapAppointmentStatusToPaymentStatus(String appointmentStatus) {
    final normalized = appointmentStatus.toLowerCase().trim();

    // Success states
    if (normalized == 'confirmed' ||
        normalized == 'active' ||
        normalized == 'booked') {
      return 'completed';
    }

    // Failure states
    if (normalized == 'cancelled' ||
        normalized == 'canceled' ||
        normalized == 'failed' ||
        normalized == 'declined' ||
        normalized == 'payment failed') {
      return 'failed';
    }

    // Processing states
    if (normalized == 'processing payment' ||
        normalized == 'payment initiated') {
      return 'processing';
    }

    // Pending states
    if (normalized == 'pending payment' ||
        normalized == 'pending' ||
        normalized == 'awaiting payment') {
      return 'pending';
    }

    // Default: treat as pending
    log.w('⚠️ Unknown appointment status "$appointmentStatus", treating as pending');
    return 'pending';
  }

  /// Check if a status is terminal (final state)
  bool _isTerminalStatus(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'completed' ||
        normalized == 'success' ||
        normalized == 'successful' ||
        normalized == 'failed' ||
        normalized == 'declined' ||
        normalized == 'rejected' ||
        normalized == 'cancelled' ||
        normalized == 'canceled' ||
        normalized == 'expired';
  }

  Future<void> _cancelSubscriptions() async {
    await _transactionSubscription?.cancel();
    await _appointmentSubscription?.cancel();
    _transactionSubscription = null;
    _appointmentSubscription = null;
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}

/// Internal event for status changes (not exposed to UI)
class _PaymentStatusChanged extends PaymentEvent {
  final String status;
  final String transactionId;
  final String appointmentId;
  final Map<String, dynamic> data;
  final String source;

  const _PaymentStatusChanged({
    required this.status,
    required this.transactionId,
    required this.appointmentId,
    required this.data,
    required this.source,
  });

  @override
  List<Object?> get props => [status, transactionId, appointmentId, data, source];
}