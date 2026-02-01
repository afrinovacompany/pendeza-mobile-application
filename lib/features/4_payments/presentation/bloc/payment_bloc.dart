import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pendeza/app/utils/logger.dart';
import '../../../../app/services/payment_service.dart';
import '../../../../app/services/service_locator.dart';
import 'payment_event.dart';
import 'payment_state.dart';

/// 🔥 REFACTORED PaymentBloc - Reactive & Webhook-Based
///
/// **Benefits:**
/// ✅ No polling = better battery life
/// ✅ Real-time updates via Firestore
/// ✅ Works even after app restart
/// ✅ Simpler code
/// ✅ Webhook handles all backend logic
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

  /// Initiate payment with PalmPesa
  Future<void> _onInitiatePayment(
      InitiatePayment event,
      Emitter<PaymentState> emit,
      ) async {
    try {
      log.i('PaymentBloc: Initiating payment for appointment ${event.appointmentId}');
      emit(PaymentLoading());

      // 🔥 FIX: Pass userId so transaction document can be created with proper permissions
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

        final transactionId = result['transactionId'];

        // Show user feedback
        emit(const PaymentInitiated(
          "Payment request sent! Complete payment on your phone.",
        ));

        // Start listening to BOTH transaction document AND appointment
        log.i('👂 Starting to watch payment status');
        add(WatchPaymentStatus(
          transactionId: transactionId,
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
  /// 1. Transaction listener - catches webhook updates to transaction doc
  /// 2. Appointment listener - catches updates to appointment status
  Future<void> _onWatchPaymentStatus(
      WatchPaymentStatus event,
      Emitter<PaymentState> emit,
      ) async {
    try {
      log.i('👂 Setting up payment status listeners');
      log.i('   Transaction ID: ${event.transactionId}');
      log.i('   Appointment ID: ${event.appointmentId}');

      // Cancel any existing subscriptions
      await _transactionSubscription?.cancel();
      await _appointmentSubscription?.cancel();

      // ========================================
      // LISTENER 1: Transaction Document
      // ========================================
      if (event.transactionId != null && event.transactionId!.isNotEmpty) {
        log.i('👂 Setting up transaction listener: ${event.transactionId}');

        _transactionSubscription = _firestore
            .collection('transactions')
            .doc(event.transactionId)
            .snapshots()
            .listen(
              (snapshot) {
            if (!snapshot.exists) {
              log.w('⚠️ Transaction document does not exist yet: ${event.transactionId}');
              return;
            }

            final data = snapshot.data();
            if (data == null) return;

            final status = data['status']?.toString().toLowerCase() ?? 'pending';
            log.d('📡 Transaction status update: $status');

            // Only emit for terminal states
            if (status == 'completed' || status == 'failed') {
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
          },
        );
      }

      // ========================================
      // LISTENER 2: Appointment Document (ALWAYS)
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

          // Map appointment status to payment status
          String paymentStatus;
          if (status == 'Confirmed' || status == 'confirmed') {
            paymentStatus = 'completed';
          } else if (status == 'Cancelled' || status == 'cancelled' || status == 'Failed') {
            paymentStatus = 'failed';
          } else {
            paymentStatus = 'pending';
          }

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
        log.i('✅ Payment COMPLETED! (from ${event.source})');
        await _cancelSubscriptions();
        emit(PaymentSuccess(event.appointmentId));
        break;

      case 'failed':
        log.w('❌ Payment FAILED (from ${event.source})');
        await _cancelSubscriptions();
        final errorMsg = event.data['errorMessage'] ??
            event.data['failureReason'] ??
            'Payment failed';
        emit(PaymentError(errorMsg));
        break;

      case 'processing':
        log.i('⏳ Payment is being processed...');
        emit(const PaymentInitiated(
          "Processing payment... This may take a moment.",
        ));
        break;

      case 'pending':
        log.d('⏳ Payment still pending...');
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