// =============================================================================
// WalletBloc - REACTIVE FIRESTORE-BASED VERSION
// =============================================================================
// 🔥 REFACTORED APPROACH:
// 1. NO MORE POLLING - Saves battery and data
// 2. Uses Firestore real-time listeners for deposits
// 3. Webhook (Cloud Function) updates Firestore when payment completes
// 4. UI reacts instantly when status changes
// 5. Works even if user closes and reopens app
// =============================================================================

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pendeza/app/services/payment_service.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/shared/models/wallet_model.dart';
import 'package:pendeza/shared/models/transaction_model.dart';
import 'package:pendeza/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_state.dart';

/// 🔥 WalletBloc - Reactive & Webhook-Based
///
/// **OLD APPROACH (Removed):**
/// - Complex polling logic that checked PalmPesa API every 5 seconds
/// - Wasted battery and data
/// - Could miss payments if app was closed
/// - Had timeout issues
///
/// **NEW APPROACH (Current):**
/// - App creates transaction document when user initiates deposit
/// - App listens to that document for status changes
/// - Webhook updates document when PalmPesa confirms payment
/// - WalletService credits wallet automatically (via webhook OR manual refresh)
/// - UI updates instantly via Firestore listener
///
/// **Benefits:**
/// ✅ No polling = better battery life & less data usage
/// ✅ Real-time updates
/// ✅ Works even after app restart
/// ✅ Simpler, cleaner code
/// ✅ More reliable
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository walletRepository;
  final PaymentService paymentService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream subscriptions
  StreamSubscription<DocumentSnapshot>? _depositListener;
  StreamSubscription<List<TransactionModel>>? _transactionHistoryListener;
  StreamSubscription<DocumentSnapshot>? _walletListener;

  static const Duration _successMessageDuration = Duration(seconds: 3);

  WalletBloc({
    required this.walletRepository,
    required this.paymentService,
  }) : super(const WalletInitial()) {
    // Register event handlers
    on<LoadWallet>(_onLoadWallet);
    on<InitiateDeposit>(_onInitiateDeposit);
    on<WatchDepositStatus>(_onWatchDepositStatus);
    on<_DepositStatusChanged>(_onDepositStatusChanged);
    on<RefreshWallet>(_onRefreshWallet);
    on<CancelDepositWatch>(_onCancelDepositWatch);
    on<PayFromWallet>(_onPayFromWallet);
  }

  /// Load wallet data for a user
  Future<void> _onLoadWallet(
      LoadWallet event,
      Emitter<WalletState> emit,
      ) async {
    try {
      log.i('WalletBloc: Loading wallet for user ${event.userId}');
      emit(const WalletLoading());

      final wallet = await walletRepository.getOrCreateWallet(event.userId);
      log.i('WalletBloc: Wallet loaded. Balance: ${wallet.formattedBalance}');

      emit(WalletLoaded(
        wallet: wallet,
        recentTransactions: const [],
      ));

      // Load recent transactions in background
      final transactions = await walletRepository.getRecentTransactions(event.userId);
      emit(WalletLoaded(
        wallet: wallet,
        recentTransactions: transactions,
      ));
    } catch (e, stackTrace) {
      log.e('WalletBloc: Error loading wallet', error: e, stackTrace: stackTrace);
      emit(WalletError(message: 'Failed to load wallet: ${e.toString()}'));
    }
  }

  /// Initiate a wallet deposit via PalmPesa USSD Push
  ///
  /// Steps:
  /// 1. Call PalmPesa API to send USSD prompt to user's phone
  /// 2. PaymentService creates transaction document in Firestore (status: 'pending')
  /// 3. Start listening to that transaction document
  /// 4. When webhook updates it to 'completed', credit wallet
  Future<void> _onInitiateDeposit(
      InitiateDeposit event,
      Emitter<WalletState> emit,
      ) async {
    try {
      log.i('WalletBloc: Initiating deposit');
      log.i('   User: ${event.userId}');
      log.i('   Amount: TZS ${event.amount.toStringAsFixed(0)}');
      log.i('   Phone: ${event.phoneNumber}');

      emit(const DepositInProgress(
        message: 'Initiating payment...',
      ));

      // Call PalmPesa API
      final result = await paymentService.initiateWalletTopUp(
        userId: event.userId,
        phoneNumber: event.phoneNumber,
        amount: event.amount,
        userName: event.userName,
        userEmail: event.userEmail,
      );

      log.d('WalletBloc: Deposit initiation result: $result');

      if (result['success'] == true) {
        log.i('✅ WalletBloc: Deposit initiated successfully');

        final transactionId = result['transactionId'];
        final gatewayOrderId = result['gatewayOrderId'];
        final message = result['message'] ?? 'Check your phone to complete payment.';

        if (transactionId != null) {
          // Show user feedback
          emit(DepositInProgress(
            message: message,
            transactionId: transactionId,
            gatewayOrderId: gatewayOrderId,
          ));

          // Start listening for status updates
          log.i('👂 Starting to watch transaction: $transactionId');
          add(WatchDepositStatus(
            userId: event.userId,
            transactionId: transactionId,
            amount: event.amount,
          ));
        } else {
          log.w('⚠️ No transactionId returned');
          emit(const DepositError(
            'Deposit initiated but tracking unavailable. Please check your balance.',
          ));
        }
      } else {
        final errorMsg = result['message'] ?? 'Deposit initiation failed';
        log.e('❌ WalletBloc: Deposit failed - $errorMsg');
        emit(DepositError(errorMsg));
      }
    } catch (e, stackTrace) {
      log.e('WalletBloc: Exception during deposit', error: e, stackTrace: stackTrace);
      emit(DepositError('Failed to initiate deposit: ${e.toString()}'));
    }
  }

  /// Watch transaction document for status changes (REACTIVE)
  ///
  /// Sets up Firestore listener on the transaction document.
  /// When webhook updates status to 'completed', we get notified immediately!
  Future<void> _onWatchDepositStatus(
      WatchDepositStatus event,
      Emitter<WalletState> emit,
      ) async {
    try {
      log.i('👂 Setting up listener for transaction: ${event.transactionId}');

      // Cancel any existing listener
      await _depositListener?.cancel();

      // Listen to the transaction document
      _depositListener = _firestore
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
          if (data == null) {
            log.w('⚠️ Transaction document has no data');
            return;
          }

          final status = data['status']?.toString().toLowerCase() ?? 'pending';
          log.d('📡 Transaction status update: $status');

          // Add internal event to process the status change
          add(_DepositStatusChanged(
            userId: event.userId,
            transactionId: event.transactionId,
            status: status,
            amount: event.amount,
            data: data,
          ));
        },
        onError: (error) {
          log.e('❌ Error listening to transaction status', error: error);
          add(_DepositStatusChanged(
            userId: event.userId,
            transactionId: event.transactionId,
            status: 'error',
            amount: event.amount,
            data: {'error': error.toString()},
          ));
        },
      );

      log.i('✅ Listener set up successfully');
    } catch (e, stackTrace) {
      log.e('❌ Error setting up deposit listener', error: e, stackTrace: stackTrace);
      emit(DepositError('Failed to track deposit: ${e.toString()}'));
    }
  }

  /// Handle status changes from Firestore listener
  Future<void> _onDepositStatusChanged(
      _DepositStatusChanged event,
      Emitter<WalletState> emit,
      ) async {
    log.i('🔄 Processing deposit status change: ${event.status}');

    switch (event.status) {
      case 'completed':
        log.i('✅ Deposit COMPLETED!');
        await _depositListener?.cancel();

        // The webhook already credited the wallet, so just reload to show new balance
        try {
          final wallet = await walletRepository.getOrCreateWallet(event.userId);
          final transactions = await walletRepository.getRecentTransactions(event.userId);

          emit(DepositSuccess(
            message: 'TZS ${event.amount.toStringAsFixed(0)} added to your wallet!',
            newBalance: wallet.balance,
          ));

          // After showing success message, go back to loaded state
          await Future.delayed(_successMessageDuration);

          if (!isClosed) {
            emit(WalletLoaded(
              wallet: wallet,
              recentTransactions: transactions,
            ));
          }
        } catch (e) {
          log.e('Error reloading wallet after deposit', error: e);
          emit(const DepositSuccess(
            message: 'Deposit successful!',
            newBalance: null,
          ));
        }
        break;

      case 'failed':
        log.w('❌ Deposit FAILED');
        await _depositListener?.cancel();
        final errorMsg = event.data['errorMessage'] ?? 'Payment failed';
        emit(DepositError(errorMsg));
        break;

      case 'processing':
        log.i('⏳ Deposit is being processed...');
        emit(DepositInProgress(
          message: 'Processing payment... Almost done!',
          transactionId: event.transactionId,
        ));
        break;

      case 'pending':
      // Still waiting - no action needed, listener will catch next update
        log.d('⏳ Deposit still pending...');
        emit(DepositInProgress(
          message: 'Waiting for payment confirmation...',
          transactionId: event.transactionId,
        ));
        break;

      case 'error':
        log.e('❌ Deposit tracking error');
        await _depositListener?.cancel();
        emit(const DepositError(
          'Error tracking deposit. Please check your wallet balance.',
        ));
        break;

      default:
        log.w('⚠️ Unknown deposit status: ${event.status}');
    }
  }

  /// Pay from wallet for a booking
  ///
  /// Debits the user's wallet to pay for an appointment
  Future<void> _onPayFromWallet(
      PayFromWallet event,
      Emitter<WalletState> emit,
      ) async {
    try {
      log.i('WalletBloc: Processing wallet payment');
      log.i('   User: ${event.userId}');
      log.i('   Salon Owner: ${event.salonOwnerId}');
      log.i('   Appointment: ${event.appointmentId}');
      log.i('   Amount: TZS ${event.amount.toStringAsFixed(0)}');

      // Get current wallet to show in processing state
      final currentWallet = await walletRepository.getOrCreateWallet(event.userId);

      // Check if user has sufficient balance
      final canAfford = await walletRepository.canAfford(event.userId, event.amount);
      if (!canAfford) {
        log.w('❌ Insufficient wallet balance');
        emit(WalletInsufficientBalance(
          wallet: currentWallet,
          requiredAmount: event.amount,
          shortfall: event.amount - currentWallet.balance,
        ));
        return;
      }

      // Emit processing state
      emit(WalletPaymentProcessing(
        wallet: currentWallet,
        paymentAmount: event.amount,
      ));

      // Debit the wallet
      final transactionId = await walletRepository.debitWalletForBooking(
        userId: event.userId,
        salonOwnerId: event.salonOwnerId,
        appointmentId: event.appointmentId,
        amount: event.amount,
        description: event.description ?? 'Booking payment',
      );

      log.i('✅ Wallet payment successful. Transaction ID: $transactionId');

      // Get updated wallet
      final updatedWallet = await walletRepository.getOrCreateWallet(event.userId);
      final transactions = await walletRepository.getRecentTransactions(event.userId);

      emit(WalletPaymentSuccess(
        wallet: updatedWallet,
        transactionId: transactionId,
        paidAmount: event.amount,
        message: 'Payment successful!',
      ));

      // After showing success message, go back to loaded state
      await Future.delayed(_successMessageDuration);

      if (!isClosed) {
        emit(WalletLoaded(
          wallet: updatedWallet,
          recentTransactions: transactions,
        ));
      }
    } catch (e, stackTrace) {
      log.e('WalletBloc: Error processing wallet payment', error: e, stackTrace: stackTrace);

      // Try to get wallet for error state
      WalletModel? wallet;
      try {
        wallet = await walletRepository.getOrCreateWallet(event.userId);
      } catch (_) {}

      emit(WalletError(
        message: 'Payment failed: ${e.toString()}',
        wallet: wallet,
      ));
    }
  }

  /// Refresh wallet data
  Future<void> _onRefreshWallet(
      RefreshWallet event,
      Emitter<WalletState> emit,
      ) async {
    try {
      log.i('WalletBloc: Refreshing wallet for user ${event.userId}');

      final wallet = await walletRepository.getOrCreateWallet(event.userId);
      final transactions = await walletRepository.getRecentTransactions(event.userId);

      emit(WalletLoaded(
        wallet: wallet,
        recentTransactions: transactions,
      ));

      log.i('WalletBloc: Wallet refreshed. Balance: ${wallet.formattedBalance}');
    } catch (e, stackTrace) {
      log.e('WalletBloc: Error refreshing wallet', error: e, stackTrace: stackTrace);
      emit(WalletError(message: 'Failed to refresh wallet: ${e.toString()}'));
    }
  }

  /// Cancel the deposit status watcher
  Future<void> _onCancelDepositWatch(
      CancelDepositWatch event,
      Emitter<WalletState> emit,
      ) async {
    log.i('🛑 Cancelling deposit status listener');
    await _depositListener?.cancel();
  }

  @override
  Future<void> close() {
    _depositListener?.cancel();
    _transactionHistoryListener?.cancel();
    _walletListener?.cancel();
    return super.close();
  }
}

/// Internal event for deposit status changes (not exposed to UI)
class _DepositStatusChanged extends WalletEvent {
  final String userId;
  final String transactionId;
  final String status;
  final double amount;
  final Map<String, dynamic> data;

  const _DepositStatusChanged({
    required this.userId,
    required this.transactionId,
    required this.status,
    required this.amount,
    required this.data,
  });

  @override
  List<Object?> get props => [userId, transactionId, status, amount, data];
}