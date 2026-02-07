import 'package:equatable/equatable.dart';

/// Base class for all wallet events
abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Load wallet data for a user
class LoadWallet extends WalletEvent {
  final String userId;

  const LoadWallet(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Event: Initiate a wallet deposit via PalmPesa
class InitiateDeposit extends WalletEvent {
  final String userId;
  final String phoneNumber;
  final double amount;
  final String userName;
  final String userEmail;

  const InitiateDeposit({
    required this.userId,
    required this.phoneNumber,
    required this.amount,
    required this.userName,
    required this.userEmail,
  });

  @override
  List<Object?> get props => [userId, phoneNumber, amount, userName, userEmail];
}

/// Event: Start watching deposit status (REACTIVE)
///
/// Sets up Firestore listener to watch transaction document.
/// When webhook updates status to 'completed', listener triggers state change.
class WatchDepositStatus extends WalletEvent {
  final String userId;
  final String transactionId;
  final double amount;

  const WatchDepositStatus({
    required this.userId,
    required this.transactionId,
    required this.amount,
  });

  @override
  List<Object?> get props => [userId, transactionId, amount];
}

/// Event: Refresh wallet data
///
/// Manually reload wallet balance and transactions from Firestore
class RefreshWallet extends WalletEvent {
  final String userId;

  const RefreshWallet(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Event: Cancel the deposit status watcher
///
/// Stops listening to Firestore when user navigates away
class CancelDepositWatch extends WalletEvent {
  const CancelDepositWatch();
}

/// Event: Pay from wallet for a booking
///
/// Debits the wallet to pay for an appointment/booking
class PayFromWallet extends WalletEvent {
  final String userId;
  final String salonOwnerId;
  final String appointmentId;
  final double amount;
  final String? description;

  const PayFromWallet({
    required this.userId,
    required this.salonOwnerId,
    required this.appointmentId,
    required this.amount,
    this.description,
  });

  @override
  List<Object?> get props => [userId, salonOwnerId, appointmentId, amount, description];
}