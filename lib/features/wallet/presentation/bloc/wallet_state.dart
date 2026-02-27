import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/wallet_model.dart';
import 'package:pendeza/shared/models/transaction_model.dart';

/// Base class for all wallet states
abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

/// Initial state before wallet is loaded
class WalletInitial extends WalletState {
  const WalletInitial();
}

/// Wallet is being loaded
class WalletLoading extends WalletState {
  const WalletLoading();
}

/// Wallet loaded successfully with balance and recent transactions
class WalletLoaded extends WalletState {
  final WalletModel wallet;
  final List<TransactionModel> recentTransactions;

  const WalletLoaded({
    required this.wallet,
    this.recentTransactions = const [],
  });

  /// Helper: Get formatted balance
  String get formattedBalance => wallet.formattedBalance;

  /// Helper: Check if wallet is active
  bool get isActive => wallet.isActive;

  /// Helper: Check if user has any balance
  bool get hasBalance => wallet.hasBalance;

  @override
  List<Object?> get props => [wallet, recentTransactions];

  WalletLoaded copyWith({
    WalletModel? wallet,
    List<TransactionModel>? recentTransactions,
  }) {
    return WalletLoaded(
      wallet: wallet ?? this.wallet,
      recentTransactions: recentTransactions ?? this.recentTransactions,
    );
  }
}

/// Deposit flow states
/// These represent the multi-step deposit process

/// User is initiating a deposit (calling PalmPesa API)
class WalletDepositInitiating extends WalletState {
  final WalletModel wallet;
  final double depositAmount;

  const WalletDepositInitiating({
    required this.wallet,
    required this.depositAmount,
  });

  @override
  List<Object?> get props => [wallet, depositAmount];
}

/// Deposit initiated, waiting for user to complete payment on phone
class WalletDepositPending extends WalletState {
  final WalletModel wallet;
  final String gatewayOrderId;
  final double depositAmount;
  final String message;

  const WalletDepositPending({
    required this.wallet,
    required this.gatewayOrderId,
    required this.depositAmount,
    this.message = 'Check your phone to complete the payment',
  });

  @override
  List<Object?> get props => [wallet, gatewayOrderId, depositAmount, message];
}

/// Deposit confirmed! Money has been credited to wallet
class WalletDepositSuccess extends WalletState {
  final WalletModel wallet;
  final double depositedAmount;
  final String message;

  const WalletDepositSuccess({
    required this.wallet,
    required this.depositedAmount,
    this.message = 'Deposit successful! Your wallet has been credited.',
  });

  @override
  List<Object?> get props => [wallet, depositedAmount, message];
}

// =============================================================================
// 🆕 NEW REACTIVE STATES (Used by refactored WalletBloc)
// =============================================================================

/// Deposit is in progress (waiting for payment confirmation)
/// This replaces the old WalletDepositPending state
class DepositInProgress extends WalletState {
  final String message;
  final String? transactionId;
  final String? gatewayOrderId;
  final WalletModel? wallet; // Keep last known wallet to prevent blank screen

  const DepositInProgress({
    required this.message,
    this.transactionId,
    this.gatewayOrderId,
    this.wallet,
  });

  @override
  List<Object?> get props => [message, transactionId, gatewayOrderId, wallet];
}

/// Deposit succeeded!
class DepositSuccess extends WalletState {
  final String message;
  final double? newBalance;

  const DepositSuccess({
    required this.message,
    this.newBalance,
  });

  @override
  List<Object?> get props => [message, newBalance];
}

/// Deposit failed with error
class DepositError extends WalletState {
  final String message;

  const DepositError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Payment from wallet states

/// Processing payment from wallet
class WalletPaymentProcessing extends WalletState {
  final WalletModel wallet;
  final double paymentAmount;

  const WalletPaymentProcessing({
    required this.wallet,
    required this.paymentAmount,
  });

  @override
  List<Object?> get props => [wallet, paymentAmount];
}

/// Payment from wallet successful
class WalletPaymentSuccess extends WalletState {
  final WalletModel wallet;
  final String transactionId;
  final double paidAmount;
  final String message;

  const WalletPaymentSuccess({
    required this.wallet,
    required this.transactionId,
    required this.paidAmount,
    this.message = 'Payment successful!',
  });

  @override
  List<Object?> get props => [wallet, transactionId, paidAmount, message];
}

/// Insufficient balance for payment
class WalletInsufficientBalance extends WalletState {
  final WalletModel wallet;
  final double requiredAmount;
  final double shortfall;
  final String message;

  const WalletInsufficientBalance({
    required this.wallet,
    required this.requiredAmount,
    required this.shortfall,
    String? message,
  }) : message = message ?? 'Insufficient balance. Please top up your wallet.';

  /// Get suggested top-up amount (round up to nearest 10,000)
  double get suggestedTopUp {
    return ((shortfall / 10000).ceil() * 10000).toDouble();
  }

  @override
  List<Object?> get props => [wallet, requiredAmount, shortfall, message];
}

/// Refund processing
class WalletRefundProcessing extends WalletState {
  final WalletModel wallet;
  final double refundAmount;

  const WalletRefundProcessing({
    required this.wallet,
    required this.refundAmount,
  });

  @override
  List<Object?> get props => [wallet, refundAmount];
}

/// Refund completed successfully
class WalletRefundSuccess extends WalletState {
  final WalletModel wallet;
  final double refundedAmount;
  final String message;

  const WalletRefundSuccess({
    required this.wallet,
    required this.refundedAmount,
    this.message = 'Refund processed successfully',
  });

  @override
  List<Object?> get props => [wallet, refundedAmount, message];
}

/// Wallet operation failed with error
class WalletError extends WalletState {
  final String message;
  final WalletModel? wallet; // Optional: Keep wallet data even on error

  const WalletError({
    required this.message,
    this.wallet,
  });

  @override
  List<Object?> get props => [message, wallet];
}

/// Wallet is frozen/suspended
class WalletFrozen extends WalletState {
  final WalletModel wallet;
  final String reason;

  const WalletFrozen({
    required this.wallet,
    required this.reason,
  });

  @override
  List<Object?> get props => [wallet, reason];
}

/// Transaction history loaded
class WalletTransactionsLoaded extends WalletState {
  final WalletModel wallet;
  final List<TransactionModel> transactions;

  const WalletTransactionsLoaded({
    required this.wallet,
    required this.transactions,
  });

  @override
  List<Object?> get props => [wallet, transactions];
}