// =============================================================================
// PAYMENT SCREEN - Main Entry Point (Refactored)
// =============================================================================
// This is the main payment screen that orchestrates the payment flow.
// It has been refactored from 858 lines to ~150 lines by extracting:
// - PaymentArguments → models/payment_arguments.dart
// - PaymentMethod enum → models/payment_method.dart
// - Widgets → widgets/ folder
// - WebView → screens/payment_webview_screen.dart
// =============================================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/widgets/custom_snackbar.dart';

// Wallet imports
import 'package:pendeza/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_state.dart';

// Payment module imports
import '../bloc/payment_bloc.dart';
import '../bloc/payment_state.dart';
import '../models/payment_arguments.dart';
import '../widgets/payment_body.dart';

/// Re-export PaymentArguments for use by other modules (router, booking, etc.)
export '../models/payment_arguments.dart';
export '../models/payment_method.dart';

/// Main Payment Screen
///
/// This screen handles all payment methods:
/// - Wallet payment (instant)
/// - Pay by Link (web-based)
/// - USSD Push (phone prompt)
class PaymentMethodSelectionScreen extends StatefulWidget {
  final PaymentArguments args;

  const PaymentMethodSelectionScreen({super.key, required this.args});

  @override
  State<PaymentMethodSelectionScreen> createState() =>
      _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState
    extends State<PaymentMethodSelectionScreen> {
  StreamSubscription<DocumentSnapshot>? _paymentStatusSubscription;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _startListeningToPaymentStatus();
  }

  @override
  void dispose() {
    _paymentStatusSubscription?.cancel();
    super.dispose();
  }

  /// Listen to Firestore for real-time payment status updates
  void _startListeningToPaymentStatus() {
    _paymentStatusSubscription = FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.args.appointmentId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;
      final status = data['status'] as String?;

      if (status == AppointmentStatus.confirmed) {
        _handlePaymentSuccess();
      } else if (status == AppointmentStatus.paymentFailed) {
        _handlePaymentFailure('Payment was declined. Please try again.');
      }
    }, onError: (error) {
      log.e('Error listening to payment status', error: error);
    });
  }

  void _handlePaymentSuccess() {
    if (!mounted) return;

    // Close any open dialogs
    Navigator.of(context).popUntil(
          (route) => route.settings.name != 'PaymentDialog',
    );

    CustomSnackBar.show(
      context,
      message: 'Payment successful! Your booking is confirmed.',
      type: SnackBarType.success,
    );
    context.go('/client/bookings');
  }

  void _handlePaymentFailure(String message) {
    if (!mounted) return;
    setState(() => _isProcessingPayment = false);

    Navigator.of(context).popUntil(
          (route) => route.settings.name != 'PaymentDialog',
    );

    CustomSnackBar.show(
      context,
      message: message,
      type: SnackBarType.error,
    );
  }

  void _showCancelConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text(
          'If you leave without paying, your booking will not be confirmed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Continue Payment'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _cancelPendingAppointment();
              context.go('/client/bookings');
            },
            child: Text(
              'Cancel Booking',
              style: TextStyle(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelPendingAppointment() async {
    try {
      final firestoreService = sl<FirestoreService>();
      await firestoreService.updateAppointmentStatus(
        widget.args.appointmentId,
        AppointmentStatus.cancelled,
      );
      log.i('Cancelled pending appointment: ${widget.args.appointmentId}');
    } catch (e, s) {
      log.e('Error cancelling appointment', error: e, stackTrace: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 FIX: Provide PaymentBloc at the top level of this screen
    // This fixes the "Could not find Provider<PaymentBloc>" error
    return BlocProvider<PaymentBloc>(
      create: (context) => PaymentBloc(),
      child: MultiBlocListener(
        listeners: [
          // Wallet payment listener
          BlocListener<WalletBloc, WalletState>(
            listener: (context, state) {
              if (state is WalletPaymentSuccess) {
                _handlePaymentSuccess();
              } else if (state is WalletInsufficientBalance) {
                setState(() => _isProcessingPayment = false);
                CustomSnackBar.show(
                  context,
                  message: 'Insufficient wallet balance. Please top up or use another payment method.',
                  type: SnackBarType.error,
                );
              } else if (state is WalletError) {
                setState(() => _isProcessingPayment = false);
                CustomSnackBar.show(
                  context,
                  message: state.message,
                  type: SnackBarType.error,
                );
              }
            },
          ),
          // Payment (USSD/Link) listener
          BlocListener<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state is PaymentSuccess) {
                _handlePaymentSuccess();
              } else if (state is PaymentError) {
                setState(() => _isProcessingPayment = false);
                CustomSnackBar.show(
                  context,
                  message: state.message,
                  type: SnackBarType.error,
                );
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Payment'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _showCancelConfirmationDialog(context),
            ),
          ),
          body: PaymentBody(
            args: widget.args,
            isProcessingPayment: _isProcessingPayment,
            onPaymentStarted: () => setState(() => _isProcessingPayment = true),
            onPaymentEnded: () => setState(() => _isProcessingPayment = false),
            onPaymentSuccess: _handlePaymentSuccess,
            onPaymentFailure: _handlePaymentFailure,
          ),
        ),
      ),
    );
  }
}