import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/shared/models/wallet_model.dart';
import 'package:pendeza/shared/models/transaction_model.dart';

/// Service for managing wallet operations.
///
/// Handles:
/// - Wallet creation and retrieval
/// - Balance queries
/// - Deposits (crediting wallet — called by Cloud Function webhook)
/// - Payments (debiting wallet for bookings)
/// - Refunds
/// - Transaction history
///
/// BUSINESS RULES:
/// - No negative balances allowed
/// - All amounts must be positive
/// - Wallet must be 'active' to perform operations
/// - All operations use Firestore transactions for atomicity
class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //============================================================================
  // WALLET CREATION & RETRIEVAL
  //============================================================================

  /// Get or create a wallet for a user.
  /// If wallet doesn't exist, creates a new one with 0 balance.
  Future<WalletModel> getOrCreateWallet(String userId) async {
    try {
      log.i('WalletService: Getting/creating wallet for user: $userId');

      final walletDoc = await _db.collection('wallets').doc(userId).get();

      if (walletDoc.exists) {
        log.d('WalletService: Wallet found for user: $userId');
        return WalletModel.fromFirestore(walletDoc);
      }

      log.i('WalletService: Creating new wallet for user: $userId');
      final newWallet = WalletModel.createNew(userId: userId);
      await _db.collection('wallets').doc(userId).set(newWallet.toFirestore());

      log.i('WalletService: New wallet created successfully');
      return newWallet;
    } catch (e, s) {
      log.e('WalletService: Error getting/creating wallet', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Get wallet balance for a user. Returns 0 if wallet doesn't exist.
  Future<double> getBalance(String userId) async {
    try {
      final wallet = await getOrCreateWallet(userId);
      return wallet.balance;
    } catch (e, s) {
      log.e('WalletService: Error getting balance', error: e, stackTrace: s);
      return 0.0;
    }
  }

  /// Check if user can afford a specific amount.
  Future<bool> canAfford(String userId, double amount) async {
    try {
      if (amount <= 0) return false;
      final balance = await getBalance(userId);
      return balance >= amount;
    } catch (e, s) {
      log.e('WalletService: Error checking affordability', error: e, stackTrace: s);
      return false;
    }
  }

  //============================================================================
  // CREDIT OPERATIONS (Add money to wallet)
  //============================================================================

  /// Credit wallet after successful Snippe payment.
  ///
  /// NOTE: In production this is called by the Cloud Function webhook,
  /// not directly from the Flutter app. The [snippeReference] is the
  /// UUID returned by Snippe (stored in the transaction doc as 'snippeReference').
  ///
  /// Steps:
  /// 1. Check for duplicate — prevent double-crediting the same payment
  /// 2. Add amount to wallet balance atomically
  /// 3. Update totalDeposited
  /// 4. Create transaction record
  Future<void> creditWallet({
    required String userId,
    required double amount,
    required String snippeReference, // FIX: was gatewayOrderId (PalmPesa field)
    String? description,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Credit amount must be positive');
    }

    try {
      log.i('WalletService: Crediting wallet for user: $userId, amount: $amount');

      // FIX: Check for duplicate using snippeReference field (not gatewayOrderId)
      final existingTxn = await _db
          .collection('transactions')
          .where('snippeReference', isEqualTo: snippeReference)
          .where('status', isEqualTo: TransactionStatus.completed.name)
          .limit(1)
          .get();

      if (existingTxn.docs.isNotEmpty) {
        log.w('WalletService: Transaction already processed: $snippeReference');
        return; // Already credited — idempotency guard
      }

      await _db.runTransaction((transaction) async {
        final walletRef = _db.collection('wallets').doc(userId);
        final walletDoc = await transaction.get(walletRef);

        WalletModel wallet;
        if (walletDoc.exists) {
          wallet = WalletModel.fromFirestore(walletDoc);
        } else {
          wallet = WalletModel.createNew(userId: userId);
        }

        final updatedWallet = wallet.copyWith(
          balance: wallet.balance + amount,
          totalDeposited: wallet.totalDeposited + amount,
          lastUpdated: DateTime.now(),
        );

        transaction.set(walletRef, updatedWallet.toFirestore());

        // Create transaction record with snippeReference
        // FIX: Store as snippeReference not gatewayOrderId
        final txn = TransactionModel.deposit(
          userId: userId,
          amount: amount,
          gatewayOrderId: snippeReference, // model field name kept for compatibility
          description: description,
        ).copyWith(
          status: TransactionStatus.completed,
          completedAt: DateTime.now(),
        );

        final txnRef = _db.collection('transactions').doc();
        transaction.set(txnRef, txn.toFirestore());

        log.i('WalletService: Wallet credited successfully. New balance: ${updatedWallet.balance}');
      });
    } catch (e, s) {
      log.e('WalletService: Error crediting wallet', error: e, stackTrace: s);
      rethrow;
    }
  }

  //============================================================================
  // DEBIT OPERATIONS (Remove money from wallet)
  //============================================================================

  /// Debit wallet for booking payment.
  ///
  /// Steps:
  /// 1. Check balance (early exit if insufficient)
  /// 2. Deduct amount atomically
  /// 3. Update totalSpent
  /// 4. Create payment transaction record
  /// 5. Update appointment status to 'Confirmed'
  /// 6. Return transaction ID
  Future<String> debitWalletForBooking({
    required String userId,
    required String salonOwnerId,
    required String appointmentId,
    required double amount,
    String? description,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Debit amount must be positive');
    }

    try {
      log.i('WalletService: Debiting wallet for booking. User: $userId, Amount: $amount');

      final canPay = await canAfford(userId, amount);
      if (!canPay) {
        log.w('WalletService: Insufficient balance for user: $userId');
        throw Exception('Insufficient wallet balance');
      }

      String? transactionId;

      await _db.runTransaction((transaction) async {
        final walletRef = _db.collection('wallets').doc(userId);
        final walletDoc = await transaction.get(walletRef);

        if (!walletDoc.exists) {
          throw Exception('Wallet not found');
        }

        final wallet = WalletModel.fromFirestore(walletDoc);

        if (!wallet.isActive) {
          throw Exception('Wallet is not active');
        }

        // Double-check balance inside transaction (race condition protection)
        if (wallet.balance < amount) {
          throw Exception('Insufficient balance');
        }

        final updatedWallet = wallet.copyWith(
          balance: wallet.balance - amount,
          totalSpent: wallet.totalSpent + amount,
          lastUpdated: DateTime.now(),
        );

        transaction.set(walletRef, updatedWallet.toFirestore());

        final txn = TransactionModel.payment(
          userId: userId,
          salonOwnerId: salonOwnerId,
          appointmentId: appointmentId,
          amount: amount,
          description: description,
        );

        final txnRef = _db.collection('transactions').doc();
        transaction.set(txnRef, txn.toFirestore());
        transactionId = txnRef.id;

        // Update appointment status to 'Confirmed'
        final appointmentRef = _db.collection('appointments').doc(appointmentId);
        transaction.update(appointmentRef, {
          'status': 'Confirmed',
          'paymentMethod': 'wallet',
          'paymentTransactionId': txnRef.id,
          'paidAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        log.i('WalletService: Wallet debited and appointment confirmed. '
            'New balance: ${updatedWallet.balance}');
      });

      return transactionId!;
    } catch (e, s) {
      log.e('WalletService: Error debiting wallet', error: e, stackTrace: s);
      rethrow;
    }
  }

  //============================================================================
  // REFUND OPERATIONS
  //============================================================================

  /// Refund money to wallet after booking cancellation.
  Future<void> refundToWallet({
    required String userId,
    required String appointmentId,
    required double amount,
    String? reason,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Refund amount must be positive');
    }

    try {
      log.i('WalletService: Processing refund. User: $userId, Amount: $amount');

      await _db.runTransaction((transaction) async {
        final walletRef = _db.collection('wallets').doc(userId);
        final walletDoc = await transaction.get(walletRef);

        WalletModel wallet;
        if (walletDoc.exists) {
          wallet = WalletModel.fromFirestore(walletDoc);
        } else {
          wallet = WalletModel.createNew(userId: userId);
        }

        final updatedWallet = wallet.copyWith(
          balance: wallet.balance + amount,
          lastUpdated: DateTime.now(),
        );

        transaction.set(walletRef, updatedWallet.toFirestore());

        final txn = TransactionModel.refund(
          userId: userId,
          appointmentId: appointmentId,
          amount: amount,
          description: reason ?? 'Booking cancellation refund',
        );

        final txnRef = _db.collection('transactions').doc();
        transaction.set(txnRef, txn.toFirestore());

        log.i('WalletService: Refund processed. New balance: ${updatedWallet.balance}');
      });
    } catch (e, s) {
      log.e('WalletService: Error processing refund', error: e, stackTrace: s);
      rethrow;
    }
  }

  //============================================================================
  // TRANSACTION HISTORY
  //============================================================================

  /// Get all transactions for a user (stream, newest first, limit 50).
  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    try {
      return _db
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList());
    } catch (e, s) {
      log.e('WalletService: Error getting transactions', error: e, stackTrace: s);
      return Stream.value([]);
    }
  }

  /// Get recent transactions (last 10).
  Future<List<TransactionModel>> getRecentTransactions(String userId) async {
    try {
      final snapshot = await _db
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    } catch (e, s) {
      log.e('WalletService: Error getting recent transactions', error: e, stackTrace: s);
      return [];
    }
  }

  //============================================================================
  // WALLET STATUS MANAGEMENT
  //============================================================================

  /// Freeze a wallet (prevents all operations).
  Future<void> freezeWallet(String userId, {String? reason}) async {
    try {
      log.w('WalletService: Freezing wallet for user: $userId. Reason: $reason');
      await _db.collection('wallets').doc(userId).update({
        'status': 'frozen',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e, s) {
      log.e('WalletService: Error freezing wallet', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Activate a wallet (restore normal operations).
  Future<void> activateWallet(String userId) async {
    try {
      log.i('WalletService: Activating wallet for user: $userId');
      await _db.collection('wallets').doc(userId).update({
        'status': 'active',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e, s) {
      log.e('WalletService: Error activating wallet', error: e, stackTrace: s);
      rethrow;
    }
  }
}