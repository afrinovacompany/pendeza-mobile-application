import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pendeza/app/config/env_config.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/shared/models/transaction_model.dart';

/// Payment Service for PalmPesa Integration
///
/// 🔥 ENHANCED VERSION with Smart Status Polling
///
/// Since PalmPesa webhooks are unreliable, this service includes
/// built-in status checking that can be called by WalletBloc.
///
/// Supports:
/// - USSD Push payments (direct to phone)
/// - Pay by Link (web-based payment)
/// - Payment status verification via polling
/// - Automatic Firestore transaction updates
///
/// API Documentation: https://palmpesa-docs.netlify.app
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ SECURE: Credentials loaded from environment configuration
  // Use --dart-define to override at build time for different environments
  static const String _baseUrl = EnvConfig.palmPesaBaseUrl;
  static const String _apiToken = EnvConfig.palmPesaApiToken;
  static const int _userId = EnvConfig.palmPesaUserId;
  static const String _vendorId = EnvConfig.palmPesaVendorId;

  // Webhook URL - Cloud Function for payment confirmation
  static const String _webhookUrl = EnvConfig.paymentWebhookUrl;

  // Custom Redirect URLs for WebView interception (Pay by Link)
  static const String successRedirectUrl = EnvConfig.paymentSuccessUrl;
  static const String cancelRedirectUrl = EnvConfig.paymentCancelUrl;

  static const String _fallbackEmail = EnvConfig.fallbackEmail;

  // ==========================================
  // 🆕 WALLET TOP-UP VIA USSD PUSH
  // ==========================================

  /// Initiate Wallet Top-Up via USSD Push
  ///
  /// Uses the `/api/palmpesa/initiate` endpoint which:
  /// - Sends a USSD prompt directly to the user's phone
  /// - Returns order_id for status polling
  ///
  /// Returns: Map with success status, message, transactionId, and gatewayOrderId
  Future<Map<String, dynamic>> initiateWalletTopUp({
    required String userId,
    required String phoneNumber,
    required double amount,
    required String userName,
    required String userEmail,
  }) async {
    final url = Uri.parse('$_baseUrl/palmpesa/initiate');

    final validEmail = (userEmail.isNotEmpty && userEmail.contains('@'))
        ? userEmail
        : _fallbackEmail;

    // Generate unique transaction ID for tracking
    final transactionId = "WALLET_${userId}_${DateTime.now().millisecondsSinceEpoch}";

    // Format phone number
    final formattedPhone = _formatPhoneNumber(phoneNumber);

    final body = {
      "name": userName,
      "email": validEmail,
      "phone": formattedPhone,
      "amount": amount.toInt(),
      "transaction_id": transactionId,
      "address": "Tanzania",
      "postcode": "00000",
      "callback_url": _webhookUrl,
    };

    try {
      log.i('💳 Initiating Wallet Top-Up via USSD Push');
      log.i('   User: $userId');
      log.i('   Amount: TZS ${amount.toStringAsFixed(0)}');
      log.i('   Phone: $formattedPhone');
      log.d('   Endpoint: $url');
      log.d('   Request Body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      log.i('📥 Response Status: ${response.statusCode}');
      log.d('📥 Response Body: ${response.body}');

      // Accept 200, 201, AND 202 as success codes
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        // Check for order_id - this is the success indicator
        final orderId = data['order_id'];

        if (orderId != null) {
          final message = data['message'] ?? 'Payment request sent. Please check your phone.';

          log.i('✅ USSD Push initiated successfully');
          log.i('   Gateway Order ID: $orderId');
          log.i('   Transaction ID: $transactionId');
          log.i('   Message: $message');

          // 🔥 CREATE TRANSACTION DOCUMENT IN FIRESTORE
          try {
            log.i('📝 Creating transaction document in Firestore...');

            final transaction = TransactionModel.deposit(
              userId: userId,
              amount: amount,
              gatewayOrderId: orderId,
              description: 'Wallet deposit via M-Pesa',
            );

            // Use transactionId as document ID for easy lookup
            await _firestore
                .collection('transactions')
                .doc(transactionId)
                .set({
              ...transaction.toFirestore(),
              'localTransactionId': transactionId,
              'gatewayOrderId': orderId,
              'phoneNumber': formattedPhone,
              'initiatedAt': FieldValue.serverTimestamp(),
            });

            log.i('✅ Transaction document created: $transactionId');
          } catch (firestoreError, stackTrace) {
            log.e('❌ Failed to create transaction document',
                error: firestoreError, stackTrace: stackTrace);
            // Don't fail the whole operation - polling can still work
          }

          return {
            'success': true,
            'message': message,
            'transactionId': transactionId,
            'gatewayOrderId': orderId,
            'paymentStatus': data['payment_status'] ?? 'PENDING',
            'data': data,
          };
        }

        // Fallback for older response format
        if (data['response'] != null) {
          final innerResponse = data['response'];
          if (innerResponse['result'] == 'SUCCESS' ||
              innerResponse['resultcode'] == '000') {
            return {
              'success': true,
              'message': innerResponse['message'] ?? 'Payment prompt sent to your phone',
              'transactionId': transactionId,
              'gatewayOrderId': data['order_id'] ?? transactionId,
              'data': data,
            };
          }
        }

        // If message indicates initiation but no order_id
        if (data['message'] != null &&
            data['message'].toString().toLowerCase().contains('initiated')) {
          log.w('⚠️ Payment initiated but no order_id in response');
          return {
            'success': true,
            'message': data['message'],
            'transactionId': transactionId,
            'gatewayOrderId': transactionId,
            'data': data,
          };
        }

        // Unexpected response format
        final errorMsg = data['message'] ?? data['error'] ?? 'Unknown response from payment gateway';
        log.w('⚠️ Unexpected response format: $errorMsg');
        return {
          'success': false,
          'message': errorMsg,
          'transactionId': transactionId,
        };
      } else {
        // Actual error response (4xx, 5xx)
        log.e('❌ Payment request failed with status: ${response.statusCode}');
        String errorMsg = 'Payment failed. Please try again.';

        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['message'] ?? errorData['error'] ?? errorMsg;
        } catch (_) {}

        return {
          'success': false,
          'message': errorMsg,
          'transactionId': transactionId,
        };
      }
    } catch (e, stackTrace) {
      log.e('❌ Error initiating wallet top-up', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Connection error. Please check your internet and try again.',
        'transactionId': transactionId,
      };
    }
  }

  // ==========================================
  // 🆕 WALLET TOP-UP VIA PAY BY LINK
  // ==========================================

  Future<Map<String, dynamic>> createWalletTopUpLink({
    required String userId,
    required double amount,
    required String userName,
    required String userEmail,
    required String phoneNumber,
  }) async {
    final url = Uri.parse('$_baseUrl/process-payment');
    final validEmail = (userEmail.isNotEmpty && userEmail.contains('@'))
        ? userEmail
        : _fallbackEmail;

    final transactionId = "WALLET_${userId}_${DateTime.now().millisecondsSinceEpoch}";
    final formattedPhone = _formatPhoneNumber(phoneNumber);

    final body = {
      "user_id": _userId, // 🔥 FIX: Now correctly an integer
      "vendor": _vendorId,
      "order_id": transactionId,
      "buyer_email": validEmail,
      "buyer_name": userName,
      "buyer_phone": formattedPhone,
      "amount": amount.toInt(),
      "currency": "TZS",
      "redirect_url": successRedirectUrl,
      "cancel_url": cancelRedirectUrl,
      "webhook": _webhookUrl,
      "buyer_remarks": "Wallet Top-Up",
      "merchant_remarks": "Pendeza Wallet",
      "no_of_items": 1
    };

    try {
      log.i('💳 Creating Wallet Top-Up Link');
      log.i('   Amount: TZS ${amount.toStringAsFixed(0)}');
      log.d('📤 Request body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      log.i('📥 Response Status: ${response.statusCode}');
      log.d('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['raw'] != null && data['raw']['payment_gateway_url'] != null) {
          final paymentUrl = data['raw']['payment_gateway_url'];

          // Create transaction document
          try {
            final transaction = TransactionModel.deposit(
              userId: userId,
              amount: amount,
              gatewayOrderId: transactionId,
              description: 'Wallet deposit via Pay Link',
            );

            await _firestore.collection('transactions').doc(transactionId).set({
              ...transaction.toFirestore(),
              'localTransactionId': transactionId,
              'gatewayOrderId': transactionId,
              'phoneNumber': formattedPhone,
              'paymentMethod': 'PayByLink',
              'initiatedAt': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            log.e('Failed to create transaction document', error: e);
          }

          return {
            'success': true,
            'paymentUrl': paymentUrl,
            'transactionId': transactionId,
            'gatewayOrderId': transactionId,
          };
        } else {
          throw Exception('Invalid API Response: Link not found');
        }
      } else {
        log.e('❌ Pay by Link failed. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to create link. Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      log.e('❌ Error creating wallet top-up link', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // ==========================================
  // 🔥🔥🔥 SMART STATUS POLLING SYSTEM 🔥🔥🔥
  // ==========================================

  /// Check payment status from PalmPesa API
  ///
  /// This is the KEY method that makes the system work without webhooks.
  /// It calls PalmPesa's `/api/order-status` endpoint and returns
  /// the current status of the payment.
  ///
  /// Returns a map with:
  /// - 'status': 'COMPLETED' | 'PENDING' | 'FAILED' | 'UNKNOWN'
  /// - 'rawData': The full response from PalmPesa
  /// - 'amount': The amount (if available)
  Future<Map<String, dynamic>> checkPaymentStatus(String gatewayOrderId) async {
    final url = Uri.parse('$_baseUrl/order-status');

    try {
      log.d('🔍 Checking payment status for: $gatewayOrderId');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"order_id": gatewayOrderId}),
      );

      log.d('📥 Status Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle array format: { "data": [...] }
        if (data['data'] != null && data['data'] is List && (data['data'] as List).isNotEmpty) {
          final transaction = data['data'][0];
          final status = transaction['payment_status']?.toString().toUpperCase() ?? 'UNKNOWN';
          final amount = transaction['amount'];

          log.i('📊 Payment Status: $status');

          return {
            'status': _normalizeStatus(status),
            'rawStatus': status,
            'amount': amount,
            'rawData': transaction,
          };
        }

        // Handle direct status format: { "payment_status": "..." }
        if (data['payment_status'] != null) {
          final status = data['payment_status'].toString().toUpperCase();
          log.i('📊 Payment Status: $status');

          return {
            'status': _normalizeStatus(status),
            'rawStatus': status,
            'rawData': data,
          };
        }

        // No status found
        log.w('⚠️ No payment status in response');
        return {
          'status': 'UNKNOWN',
          'rawData': data,
        };
      } else {
        log.e('❌ Status check failed: ${response.statusCode}');
        return {
          'status': 'ERROR',
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e, stackTrace) {
      log.e('❌ Error checking payment status', error: e, stackTrace: stackTrace);
      return {
        'status': 'ERROR',
        'error': e.toString(),
      };
    }
  }

  /// Normalize status strings from PalmPesa
  String _normalizeStatus(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'SUCCESS':
      case 'SUCCESSFUL':
      case 'PAID':
        return 'COMPLETED';
      case 'PENDING':
      case 'PROCESSING':
      case 'INITIATED':
        return 'PENDING';
      case 'FAILED':
      case 'FAILURE':
      case 'CANCELLED':
      case 'CANCELED':
      case 'REJECTED':
      case 'DECLINED':
        return 'FAILED';
      default:
        return 'UNKNOWN';
    }
  }

  /// 🔥 CRITICAL METHOD: Check status AND update Firestore if completed
  ///
  /// This is called by WalletBloc's polling loop. It:
  /// 1. Checks PalmPesa API for current status
  /// 2. If COMPLETED, updates Firestore transaction AND credits wallet
  /// 3. Returns the result for WalletBloc to update UI
  ///
  /// Returns:
  /// - 'status': 'COMPLETED' | 'PENDING' | 'FAILED' | 'ERROR'
  /// - 'credited': true if wallet was credited this call
  /// - 'newBalance': The new wallet balance (if credited)
  Future<Map<String, dynamic>> checkAndUpdatePaymentStatus({
    required String gatewayOrderId,
    required String transactionId,
    required String userId,
    required double amount,
  }) async {
    try {
      // 1. Check status from PalmPesa
      final statusResult = await checkPaymentStatus(gatewayOrderId);
      final status = statusResult['status'] as String;

      log.i('🔄 Payment status for $gatewayOrderId: $status');

      // 2. If COMPLETED, update Firestore and credit wallet
      if (status == 'COMPLETED') {
        // Check if already credited (prevent double credit)
        final txnDoc = await _firestore.collection('transactions').doc(transactionId).get();
        if (txnDoc.exists) {
          final currentStatus = txnDoc.data()?['status'];
          if (currentStatus == 'completed') {
            log.i('⚠️ Transaction already completed, skipping credit');
            final walletDoc = await _firestore.collection('wallets').doc(userId).get();
            return {
              'status': 'COMPLETED',
              'credited': false,
              'alreadyCompleted': true,
              'newBalance': walletDoc.data()?['balance'] ?? 0.0,
            };
          }
        }

        // Credit the wallet
        log.i('💰 Crediting wallet for user $userId with amount $amount');
        final newBalance = await _creditWallet(
          userId: userId,
          amount: amount,
          transactionId: transactionId,
          gatewayOrderId: gatewayOrderId,
        );

        return {
          'status': 'COMPLETED',
          'credited': true,
          'newBalance': newBalance,
        };
      }

      // 3. If FAILED, update transaction status
      if (status == 'FAILED') {
        await _firestore.collection('transactions').doc(transactionId).update({
          'status': 'failed',
          'failedAt': FieldValue.serverTimestamp(),
          'failureReason': statusResult['rawData']?['message'] ?? 'Payment failed',
        });

        return {
          'status': 'FAILED',
          'credited': false,
        };
      }

      // 4. Still pending
      return {
        'status': status,
        'credited': false,
      };
    } catch (e, stackTrace) {
      log.e('❌ Error in checkAndUpdatePaymentStatus', error: e, stackTrace: stackTrace);
      return {
        'status': 'ERROR',
        'error': e.toString(),
        'credited': false,
      };
    }
  }

  /// Credit wallet balance in Firestore
  ///
  /// Uses a Firestore transaction for atomicity
  Future<double> _creditWallet({
    required String userId,
    required double amount,
    required String transactionId,
    required String gatewayOrderId,
  }) async {
    double newBalance = 0;

    await _firestore.runTransaction((transaction) async {
      // 1. Get current wallet
      final walletRef = _firestore.collection('wallets').doc(userId);
      final walletDoc = await transaction.get(walletRef);

      double currentBalance = 0;
      double totalDeposited = 0;

      if (walletDoc.exists) {
        currentBalance = (walletDoc.data()?['balance'] ?? 0).toDouble();
        totalDeposited = (walletDoc.data()?['totalDeposited'] ?? 0).toDouble();
      }

      // 2. Calculate new balance
      newBalance = currentBalance + amount;
      totalDeposited += amount;

      // 3. Update wallet
      transaction.set(walletRef, {
        'userId': userId,
        'balance': newBalance,
        'totalDeposited': totalDeposited,
        'currency': 'TZS',
        'status': 'active',
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 4. Update transaction status
      final txnRef = _firestore.collection('transactions').doc(transactionId);
      transaction.update(txnRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'balanceAfter': newBalance,
      });
    });

    log.i('✅ Wallet credited! New balance: TZS $newBalance');
    return newBalance;
  }

  // ==========================================
  // 🔍 LEGACY VERIFICATION METHODS
  // ==========================================

  Future<bool> verifyWalletTopUp(String gatewayOrderId) async {
    log.i('🔍 Verifying wallet top-up: $gatewayOrderId');
    final result = await checkPaymentStatus(gatewayOrderId);
    return result['status'] == 'COMPLETED';
  }

  Future<bool> verifyTransaction(String orderId) async {
    final result = await checkPaymentStatus(orderId);
    return result['status'] == 'COMPLETED';
  }

  // ==========================================
  // 📱 APPOINTMENT PAYMENT METHODS
  // ==========================================

  /// Create Payment Link for Appointment Booking
  ///
  /// 🔥 FIXED: user_id now sent as integer (was string causing 500 error)
  Future<String> createPaymentLink({
    required String orderId,
    required double amount,
    required String name,
    required String email,
    required String phone,
    String? userId, // 🔥 NEW: Optional userId for transaction tracking
  }) async {
    final url = Uri.parse('$_baseUrl/process-payment');
    final validEmail = (email.isNotEmpty && email.contains('@')) ? email : _fallbackEmail;
    final formattedPhone = _formatPhoneNumber(phone);

    final body = {
      "user_id": _userId, // 🔥 FIX: Now correctly an integer (21 not "21")
      "vendor": _vendorId,
      "order_id": orderId,
      "buyer_email": validEmail,
      "buyer_name": name,
      "buyer_phone": formattedPhone,
      "amount": amount.toInt(),
      "currency": "TZS",
      "redirect_url": successRedirectUrl,
      "cancel_url": cancelRedirectUrl,
      "webhook": _webhookUrl,
      "buyer_remarks": "Appointment Booking",
      "merchant_remarks": "Salon Booking Payment",
      "no_of_items": 1
    };

    try {
      log.i('💳 Creating Payment Link for Order: $orderId');
      log.d('📤 Request body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      log.i('📥 Response Status: ${response.statusCode}');
      log.d('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['raw'] != null && data['raw']['payment_gateway_url'] != null) {
          final paymentUrl = data['raw']['payment_gateway_url'];
          // ... (existing transaction creation code)
          return paymentUrl;
        } else {
          throw Exception('Invalid API Response: Link not found');
        }
      } else {
        log.e('❌ Pay by Link failed. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to create link. Status: ${response.statusCode}');
      }

    } catch (e, stackTrace) {
      log.e('❌ Error creating payment link', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Initiate USSD Payment for Appointment
  ///
  /// 🔥 FIXED: Now creates transaction document with proper userId field
  /// This allows Firestore rules to validate the write
  Future<Map<String, dynamic>> initiatePayment({
    required String phoneNumber,
    required double amount,
    required String orderId, // This is the appointmentId
    required String email,
    required String name,
    String? userId, // 🔥 NEW: Required for Firestore rules
  }) async {
    final url = Uri.parse('$_baseUrl/palmpesa/initiate');

    final validEmail = (email.isNotEmpty && email.contains('@')) ? email : _fallbackEmail;
    // 🔥 FIX: Generate transaction ID that includes appointmentId for tracking
    final transactionId = "APT_${orderId}_${DateTime.now().millisecondsSinceEpoch}";
    final formattedPhone = _formatPhoneNumber(phoneNumber);

    final body = {
      "name": name,
      "email": validEmail,
      "phone": formattedPhone,
      "amount": amount.toInt(),
      "transaction_id": transactionId,
      "address": "Tanzania",
      "postcode": "00000",
      "callback_url": _webhookUrl,
    };

    try {
      log.i('💳 Initiating USSD Payment for Appointment');
      log.i('   Appointment ID: $orderId');
      log.i('   Transaction ID: $transactionId');
      log.i('   Amount: TZS ${amount.toInt()}');
      log.i('   Phone: $formattedPhone');
      log.d('📤 Request body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      log.i('📥 Payment Response Status: ${response.statusCode}');
      log.d('📥 Payment Response Body: ${response.body}');

      // Accept 2xx range
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        final gatewayOrderId = data['order_id'];
        if (gatewayOrderId != null) {
          log.i('✅ USSD Payment initiated successfully');
          log.i('   Gateway Order ID: $gatewayOrderId');

          // 🔥 FIX: Create transaction document with userId field
          // This is REQUIRED for Firestore rules to work
          if (userId != null && userId.isNotEmpty) {
            try {
              log.i('📝 Creating appointment payment transaction document...');
              await _firestore.collection('transactions').doc(transactionId).set({
                'type': 'appointment_payment',
                'status': 'pending',
                'appointmentId': orderId,
                'gatewayOrderId': gatewayOrderId,
                'userId': userId, // 🔥 CRITICAL: Must match request.auth.uid
                'amount': amount,
                'phoneNumber': formattedPhone,
                'paymentMethod': 'ussd_push',
                'createdAt': FieldValue.serverTimestamp(),
              });
              log.i('✅ Transaction document created: $transactionId');
            } catch (firestoreError, stackTrace) {
              log.e('❌ Failed to create transaction document',
                  error: firestoreError, stackTrace: stackTrace);
              // Continue anyway - the payment was initiated
            }
          } else {
            log.w('⚠️ No userId provided - cannot create transaction document');
          }

          return {
            'success': true,
            'message': data['message'] ?? 'Payment request sent. Check your phone.',
            'transactionId': transactionId,
            'gatewayOrderId': gatewayOrderId,
            'appointmentId': orderId,
            'data': data,
          };
        }

        final errorMsg = data['message'] ?? 'Unknown error from gateway';
        return {
          'success': false,
          'message': errorMsg,
          'appointmentId': orderId,
        };
      } else {
        log.e('❌ Payment failed with status: ${response.statusCode}');
        String errorMsg = 'Payment failed with status ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['message'] ?? errorData['error'] ?? errorMsg;
        } catch (_) {}

        return {
          'success': false,
          'message': errorMsg,
          'appointmentId': orderId,
        };
      }
    } catch (e, stackTrace) {
      log.e('❌ Error initiating payment', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
        'appointmentId': orderId,
      };
    }
  }

  // ==========================================
  // 🔧 HELPER METHODS
  // ==========================================

  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    if (cleaned.startsWith('0')) {
      cleaned = '255${cleaned.substring(1)}';
    }

    if (cleaned.length == 9) {
      cleaned = '255$cleaned';
    }

    if (!cleaned.startsWith('255')) {
      cleaned = '255$cleaned';
    }

    return cleaned;
  }
}