import 'package:pendeza/app/services/wallet_service.dart';
import 'package:pendeza/shared/models/wallet_model.dart';
import 'package:pendeza/shared/models/transaction_model.dart';
import 'package:pendeza/app/utils/logger.dart';

/// Repository interface for wallet operations.
///
/// This repository acts as a bridge between the BLoC layer and the WalletService.
/// It provides a clean API for all wallet-related operations and handles
/// error wrapping for better error messages in the UI.
///
/// **Why use a repository?**
/// - Separates business logic from data access
/// - Makes testing easier (can mock repository)
/// - Provides consistent error handling
/// - Future-proof for multiple data sources
abstract class WalletRepository {
  /// Get or create wallet for user
  Future<WalletModel> getOrCreateWallet(String userId);

  /// Get current balance
  Future<double> getBalance(String userId);

  /// Check if user can afford amount
  Future<bool> canAfford(String userId, double amount);

  /// Credit wallet (deposits)
  Future<void> creditWallet({
    required String userId,
    required double amount,
    required String snippeReference,
    String? description,
  });

  /// Debit wallet for booking
  Future<String> debitWalletForBooking({
    required String userId,
    required String salonOwnerId,
    required String appointmentId,
    required double amount,
    String? description,
  });

  /// Refund to wallet
  Future<void> refundToWallet({
    required String userId,
    required String appointmentId,
    required double amount,
    String? reason,
  });

  /// Get transaction history (stream)
  Stream<List<TransactionModel>> getUserTransactions(String userId);

  /// Get recent transactions
  Future<List<TransactionModel>> getRecentTransactions(String userId);

  /// Freeze wallet (admin)
  Future<void> freezeWallet(String userId, {String? reason});

  /// Activate wallet (admin)
  Future<void> activateWallet(String userId);
}

/// Implementation of WalletRepository using WalletService
class WalletRepositoryImpl implements WalletRepository {
  final WalletService _walletService;

  WalletRepositoryImpl(this._walletService);

  @override
  Future<WalletModel> getOrCreateWallet(String userId) async {
    try {
      return await _walletService.getOrCreateWallet(userId);
    } catch (e, s) {
      log.e('WalletRepository: Error getting/creating wallet', error: e, stackTrace: s);
      throw _handleError(e, 'Failed to load wallet');
    }
  }

  @override
  Future<double> getBalance(String userId) async {
    try {
      return await _walletService.getBalance(userId);
    } catch (e, s) {
      log.e('WalletRepository: Error getting balance', error: e, stackTrace: s);
      throw _handleError(e, 'Failed to load wallet balance');
    }
  }

  @override
  Future<bool> canAfford(String userId, double amount) async {
    try {
      return await _walletService.canAfford(userId, amount);
    } catch (e, s) {
      log.e('WalletRepository: Error checking affordability', error: e, stackTrace: s);
      return false; // Safe default - don't throw on balance check
    }
  }

  @override
  Future<void> creditWallet({
    required String userId,
    required double amount,
    required String snippeReference,
    String? description,
  }) async {
    try {
      await _walletService.creditWallet(
        userId: userId,
        amount: amount,
        snippeReference: snippeReference,
        description: description,
      );
    } catch (e, s) {
      log.e('WalletRepository: Error crediting wallet', error: e, stackTrace: s);
      throw _handleError(e, 'Failed to add funds to wallet');
    }
  }

  @override
  Future<String> debitWalletForBooking({
    required String userId,
    required String salonOwnerId,
    required String appointmentId,
    required double amount,
    String? description,
  }) async {
    try {
      return await _walletService.debitWalletForBooking(
        userId: userId,
        salonOwnerId: salonOwnerId,
        appointmentId: appointmentId,
        amount: amount,
        description: description,
      );
    } catch (e, s) {
      log.e('WalletRepository: Error debiting wallet', error: e, stackTrace: s);

      // Provide specific error messages for common issues
      if (e.toString().contains('Insufficient')) {
        throw WalletException('Insufficient wallet balance');
      } else if (e.toString().contains('not active')) {
        throw WalletException('Wallet is temporarily unavailable');
      } else {
        throw _handleError(e, 'Failed to process payment from wallet');
      }
    }
  }

  @override
  Future<void> refundToWallet({
    required String userId,
    required String appointmentId,
    required double amount,
    String? reason,
  }) async {
    try {
      await _walletService.refundToWallet(
        userId: userId,
        appointmentId: appointmentId,
        amount: amount,
        reason: reason,
      );
    } catch (e, s) {
      log.e('WalletRepository: Error processing refund', error: e, stackTrace: s);
      throw _handleError(e, 'Failed to process refund');
    }
  }

  @override
  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    try {
      return _walletService.getUserTransactions(userId);
    } catch (e, s) {
      log.e('WalletRepository: Error getting transaction stream', error: e, stackTrace: s);
      return Stream.value([]); // Return empty stream instead of throwing
    }
  }

  @override
  Future<List<TransactionModel>> getRecentTransactions(String userId) async {
    try {
      return await _walletService.getRecentTransactions(userId);
    } catch (e, s) {
      log.e('WalletRepository: Error getting recent transactions', error: e, stackTrace: s);
      return []; // Return empty list instead of throwing
    }
  }

  @override
  Future<void> freezeWallet(String userId, {String? reason}) async {
    try {
      await _walletService.freezeWallet(userId, reason: reason);
    } catch (e, s) {
      log.e('WalletRepository: Error freezing wallet', error: e, stackTrace: s);
      throw _handleError(e, 'Failed to freeze wallet');
    }
  }

  @override
  Future<void> activateWallet(String userId) async {
    try {
      await _walletService.activateWallet(userId);
    } catch (e, s) {
      log.e('WalletRepository: Error activating wallet', error: e, stackTrace: s);
      throw _handleError(e, 'Failed to activate wallet');
    }
  }

  //============================================================================
  // ERROR HANDLING
  //============================================================================

  /// Convert technical errors to user-friendly messages
  Exception _handleError(dynamic error, String fallbackMessage) {
    if (error is WalletException) {
      return error; // Already a wallet exception
    }

    // Check for common Firebase errors
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return WalletException('You do not have permission to perform this action');
    } else if (errorStr.contains('network') || errorStr.contains('connection')) {
      return WalletException('Network error. Please check your connection');
    } else if (errorStr.contains('not found')) {
      return WalletException('Wallet not found');
    } else {
      return WalletException(fallbackMessage);
    }
  }
}

/// Custom exception for wallet-related errors
class WalletException implements Exception {
  final String message;

  WalletException(this.message);

  @override
  String toString() => message;
}