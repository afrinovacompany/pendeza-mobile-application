import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initiate a payment
///
/// 🔥 UPDATED: Now includes userId for Firestore rules compliance
class InitiatePayment extends PaymentEvent {
  final String phoneNumber;
  final double amount;
  final String appointmentId;
  final String customerName;
  final String customerEmail;
  final String userId; // 🔥 NEW: Required for creating transaction document

  const InitiatePayment({
    required this.phoneNumber,
    required this.amount,
    required this.appointmentId,
    required this.customerName,
    required this.customerEmail,
    required this.userId, // 🔥 NEW: Must pass authenticated user's ID
  });

  @override
  List<Object?> get props => [
    phoneNumber,
    amount,
    appointmentId,
    customerName,
    customerEmail,
    userId,
  ];
}

/// Event to start watching payment status
class WatchPaymentStatus extends PaymentEvent {
  final String? transactionId;
  final String appointmentId;

  const WatchPaymentStatus({
    this.transactionId,
    required this.appointmentId,
  });

  @override
  List<Object?> get props => [transactionId, appointmentId];
}

/// Event to cancel watching payment status
class CancelPaymentWatch extends PaymentEvent {
  const CancelPaymentWatch();
}

/// Event to reset payment state
class ResetPaymentState extends PaymentEvent {
  const ResetPaymentState();
}