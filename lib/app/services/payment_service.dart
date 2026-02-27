import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pendeza/app/config/env_config.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:uuid/uuid.dart';

/// Payment Service for Snippe Integration
///
/// 🔥 CORRECTED: Fixed API request structure to match Snippe requirements
///
/// API docs: https://api.snippe.sh
/// Auth:     Authorization: Bearer <api_key>
/// Payment types:
///   'mobile' → USSD push (customer gets prompt on phone)
///   'card'   → Pay by link (returns payment_url for WebView)
///
/// KEY CHANGES FROM PALMPESA:
///   ❌ Old: 'phone' → ✅ New: 'phone_number' (top level)
///   ❌ Old: 'amount', 'currency' (top level) → ✅ New: nested in 'details' object
///   ❌ Old: customer.name → ✅ New: customer.firstname + customer.lastname
///   ✅ New: Required customer address fields (address, city, state, postcode, country)
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  static const String _baseUrl = EnvConfig.snippeBaseUrl;   // https://api.snippe.sh
  static const String _apiKey  = EnvConfig.snippeApiKey;

  static const String _webhookUrl        = EnvConfig.paymentWebhookUrl;
  static const String successRedirectUrl = EnvConfig.paymentSuccessUrl;
  static const String cancelRedirectUrl  = EnvConfig.paymentCancelUrl;
  static const String _fallbackEmail     = EnvConfig.fallbackEmail;

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Snippe uses: Authorization: Bearer <api_key>
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_apiKey',
    'Content-Type':  'application/json',
    'Accept':        'application/json',
  };

  String _validEmail(String email) =>
      (email.isNotEmpty && email.contains('@')) ? email : _fallbackEmail;

  /// Split full name into first and last name
  /// 🔥 NEW: Snippe requires firstname and lastname separately
  Map<String, String> _splitName(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return {
        'firstname': parts.first,
        'lastname': parts.sublist(1).join(' '),
      };
    } else {
      return {
        'firstname': fullName.isNotEmpty ? fullName : 'Customer',
        'lastname': 'User',
      };
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WALLET TOP-UP — USSD PUSH  (payment_type: 'mobile')
  // ─────────────────────────────────────────────────────────────────────────

  /// Initiate wallet top-up — sends USSD prompt to customer's phone.
  ///
  /// Returns:
  ///   success         bool
  ///   message         user-facing string
  ///   transactionId   Firestore doc ID (WalletBloc listener watches this)
  ///   snippeReference UUID returned by Snippe
  Future<Map<String, dynamic>> initiateWalletTopUp({
    required String userId,
    required String phoneNumber,
    required double amount,
    required String userName,
    required String userEmail,
  }) async {
    final idempotencyKey  = _uuid.v4();
    final transactionId   = 'WALLET_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final formattedPhone  = _formatPhoneNumber(phoneNumber);
    final nameParts = _splitName(userName);

    // 🔥 FIXED: Corrected request body structure for Snippe
    final body = {
      'phone_number': formattedPhone,  // ← Top level with underscore (not 'phone')
      'payment_type': 'mobile',        // ← USSD push
      'webhook_url':  _webhookUrl,
      'details': {                     // ← Nested details object
        'amount':      amount.toInt(),
        'currency':    'TZS',
        'description': 'Pendeza wallet top-up',
      },
      'customer': {
        'firstname': nameParts['firstname']!,  // ← Split name
        'lastname':  nameParts['lastname']!,
        'email':     _validEmail(userEmail),
        'phone':     formattedPhone,
        // 🔥 Required address fields (use Tanzania defaults)
        'address':   'Dar es Salaam',
        'city':      'Dar es Salaam',
        'state':     'Dar es Salaam',
        'postcode':  '11000',
        'country':   'TZ',
      },
      'metadata': {
        'payment_purpose': 'wallet_topup',
        'user_id':         userId,
        'transaction_id':  transactionId,
      },
    };

    try {
      log.i('💳 Wallet top-up (USSD): user=$userId amount=$amount phone=$formattedPhone');

      final response = await http.post(
        Uri.parse('$_baseUrl/v1/payments'),
        headers: {
          ..._headers,
          'Idempotency-Key': idempotencyKey,  // prevents duplicate charges
        },
        body: jsonEncode(body),
      );

      log.i('📥 Snippe ${response.statusCode}: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final inner = data['data'] as Map<String, dynamic>? ?? data;

        final ref     = inner['reference'] as String? ?? idempotencyKey;
        final message = data['message']    as String? ??
            'Payment request sent. Please check your phone.';

        await _createTransactionDoc(
          docId:           transactionId,
          userId:          userId,
          amount:          amount,
          snippeReference: ref,
          type:            'deposit',
          phoneNumber:     formattedPhone,
          extra:           {'paymentPurpose': 'wallet_topup'},
        );

        return {
          'success':         true,
          'message':         message,
          'transactionId':   transactionId,
          'snippeReference': ref,
        };
      } else {
        final error = _extractError(response);
        log.e('❌ Wallet top-up failed: $error');
        return {'success': false, 'message': error};
      }
    } catch (e, s) {
      log.e('❌ Error initiating wallet top-up', error: e, stackTrace: s);
      return {
        'success': false,
        'message': 'Connection error. Please check your internet and try again.',
      };
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WALLET TOP-UP — PAY BY LINK  (payment_type: 'card')
  // ─────────────────────────────────────────────────────────────────────────

  /// Create a Snippe payment link for wallet top-up (opens in WebView).
  ///
  /// Returns:
  ///   success         bool
  ///   paymentUrl      URL to open in WebView
  ///   transactionId   Firestore doc ID
  ///   snippeReference UUID from Snippe
  Future<Map<String, dynamic>> createWalletTopUpLink({
    required String userId,
    required double amount,
    required String userName,
    required String userEmail,
    required String phoneNumber,
  }) async {
    final idempotencyKey = _uuid.v4();
    final transactionId  = 'WALLET_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final formattedPhone = _formatPhoneNumber(phoneNumber);
    final nameParts = _splitName(userName);

    // 🔥 FIXED: Corrected request body structure for Snippe
    final body = {
      'phone_number': formattedPhone,
      'payment_type': 'card',            // ← pay-by-link
      'webhook_url':  _webhookUrl,
      'callback_url': successRedirectUrl,
      'details': {
        'amount':      amount.toInt(),
        'currency':    'TZS',
        'description': 'Pendeza wallet top-up',
      },
      'customer': {
        'firstname': nameParts['firstname']!,
        'lastname':  nameParts['lastname']!,
        'email':     _validEmail(userEmail),
        'phone':     formattedPhone,
        'address':   'Dar es Salaam',
        'city':      'Dar es Salaam',
        'state':     'Dar es Salaam',
        'postcode':  '11000',
        'country':   'TZ',
      },
      'metadata': {
        'payment_purpose': 'wallet_topup',
        'user_id':         userId,
        'transaction_id':  transactionId,
      },
    };

    try {
      log.i('💳 Wallet top-up link: user=$userId amount=$amount');

      final response = await http.post(
        Uri.parse('$_baseUrl/v1/payments'),
        headers: {
          ..._headers,
          'Idempotency-Key': idempotencyKey,
        },
        body: jsonEncode(body),
      );

      log.i('📥 Snippe ${response.statusCode}: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data  = jsonDecode(response.body) as Map<String, dynamic>;
        final inner = data['data'] as Map<String, dynamic>? ?? data;

        final paymentUrl = inner['payment_url'] as String?;
        if (paymentUrl == null) {
          throw Exception('Snippe response missing payment_url: ${response.body}');
        }

        final ref = inner['reference'] as String? ?? idempotencyKey;

        await _createTransactionDoc(
          docId:           transactionId,
          userId:          userId,
          amount:          amount,
          snippeReference: ref,
          type:            'deposit',
          phoneNumber:     formattedPhone,
          extra:           {'paymentPurpose': 'wallet_topup', 'paymentMethod': 'pay_by_link'},
        );

        return {
          'success':         true,
          'paymentUrl':      paymentUrl,
          'transactionId':   transactionId,
          'snippeReference': ref,
        };
      } else {
        final error = _extractError(response);
        log.e('❌ Wallet top-up link failed: $error');
        return {'success': false, 'message': error};
      }
    } catch (e, s) {
      log.e('❌ Error creating wallet top-up link', error: e, stackTrace: s);
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APPOINTMENT PAYMENT — USSD PUSH  (payment_type: 'mobile')
  // ─────────────────────────────────────────────────────────────────────────

  /// Initiate appointment payment — sends USSD prompt to customer's phone.
  ///
  /// Returns:
  ///   success         bool
  ///   message         user-facing string
  ///   transactionId   Firestore doc ID (PaymentBloc listener watches this)
  ///   snippeReference UUID returned by Snippe
  ///   appointmentId   passed back for reference
  Future<Map<String, dynamic>> initiatePayment({
    required String phoneNumber,
    required double amount,
    required String orderId,        // appointmentId
    required String name,
    required String email,
    String? userId,
  }) async {
    final idempotencyKey = _uuid.v4();
    final transactionId  = 'APT_${orderId}_${DateTime.now().millisecondsSinceEpoch}';
    final formattedPhone = _formatPhoneNumber(phoneNumber);
    final nameParts = _splitName(name);

    // 🔥 FIXED: Corrected request body structure for Snippe
    final body = {
      'phone_number': formattedPhone,  // ← Top level with underscore
      'payment_type': 'mobile',        // ← USSD push
      'webhook_url':  _webhookUrl,
      'details': {                     // ← Nested details object
        'amount':      amount.toInt(),
        'currency':    'TZS',
        'description': 'Pendeza appointment booking',
      },
      'customer': {
        'firstname': nameParts['firstname']!,
        'lastname':  nameParts['lastname']!,
        'email':     _validEmail(email),
        'phone':     formattedPhone,
        'address':   'Dar es Salaam',
        'city':      'Dar es Salaam',
        'state':     'Dar es Salaam',
        'postcode':  '11000',
        'country':   'TZ',
      },
      'metadata': {
        'payment_purpose': 'appointment_booking',
        'appointment_id':  orderId,
        'user_id':         userId ?? '',
        'transaction_id':  transactionId,
      },
    };

    try {
      log.i('💳 Appointment payment (USSD): appt=$orderId amount=$amount');

      final response = await http.post(
        Uri.parse('$_baseUrl/v1/payments'),
        headers: {
          ..._headers,
          'Idempotency-Key': idempotencyKey,
        },
        body: jsonEncode(body),
      );

      log.i('📥 Snippe ${response.statusCode}: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data  = jsonDecode(response.body) as Map<String, dynamic>;
        final inner = data['data'] as Map<String, dynamic>? ?? data;

        final ref     = inner['reference'] as String? ?? idempotencyKey;
        final message = data['message']    as String? ??
            'Payment request sent. Check your phone.';

        // Only create transaction doc if we have a valid userId
        if (userId != null && userId.isNotEmpty) {
          await _createTransactionDoc(
            docId:           transactionId,
            userId:          userId,
            amount:          amount,
            snippeReference: ref,
            type:            'appointment_payment',
            phoneNumber:     formattedPhone,
            extra:           {
              'appointmentId':  orderId,
              'paymentPurpose': 'appointment_booking',
            },
          );
        }

        return {
          'success':         true,
          'message':         message,
          'transactionId':   transactionId,
          'snippeReference': ref,
          'appointmentId':   orderId,
        };
      } else {
        final error = _extractError(response);
        log.e('❌ Appointment payment failed: $error');
        return {'success': false, 'message': error, 'appointmentId': orderId};
      }
    } catch (e, s) {
      log.e('❌ Error initiating appointment payment', error: e, stackTrace: s);
      return {
        'success':       false,
        'message':       'Connection error: ${e.toString()}',
        'appointmentId': orderId,
      };
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APPOINTMENT PAYMENT — PAY BY LINK  (payment_type: 'card')
  // ─────────────────────────────────────────────────────────────────────────

  /// Create a Snippe payment link for an appointment (opens in WebView).
  /// Returns the payment URL string directly.
  Future<String> createPaymentLink({
    required String orderId,
    required double amount,
    required String name,
    required String email,
    required String phone,
    String? userId,
  }) async {
    final idempotencyKey = _uuid.v4();
    final transactionId  = 'APT_${orderId}_${DateTime.now().millisecondsSinceEpoch}';
    final formattedPhone = _formatPhoneNumber(phone);
    final nameParts = _splitName(name);

    // 🔥 FIXED: Corrected request body structure for Snippe
    final body = {
      'phone_number': formattedPhone,
      'payment_type': 'card',            // ← pay-by-link
      'webhook_url':  _webhookUrl,
      'callback_url': successRedirectUrl,
      'details': {
        'amount':      amount.toInt(),
        'currency':    'TZS',
        'description': 'Pendeza appointment booking',
      },
      'customer': {
        'firstname': nameParts['firstname']!,
        'lastname':  nameParts['lastname']!,
        'email':     _validEmail(email),
        'phone':     formattedPhone,
        'address':   'Dar es Salaam',
        'city':      'Dar es Salaam',
        'state':     'Dar es Salaam',
        'postcode':  '11000',
        'country':   'TZ',
      },
      'metadata': {
        'payment_purpose': 'appointment_booking',
        'appointment_id':  orderId,
        'user_id':         userId ?? '',
        'transaction_id':  transactionId,
      },
    };

    try {
      log.i('💳 Appointment payment link: appt=$orderId amount=$amount');

      final response = await http.post(
        Uri.parse('$_baseUrl/v1/payments'),
        headers: {
          ..._headers,
          'Idempotency-Key': idempotencyKey,
        },
        body: jsonEncode(body),
      );

      log.i('📥 Snippe ${response.statusCode}: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data  = jsonDecode(response.body) as Map<String, dynamic>;
        final inner = data['data'] as Map<String, dynamic>? ?? data;

        final paymentUrl = inner['payment_url'] as String?;
        if (paymentUrl == null) {
          throw Exception('Snippe response missing payment_url: ${response.body}');
        }

        final ref = inner['reference'] as String? ?? idempotencyKey;

        if (userId != null && userId.isNotEmpty) {
          await _createTransactionDoc(
            docId:           transactionId,
            userId:          userId,
            amount:          amount,
            snippeReference: ref,
            type:            'appointment_payment',
            phoneNumber:     formattedPhone,
            extra:           {
              'appointmentId':  orderId,
              'paymentPurpose': 'appointment_booking',
              'paymentMethod':  'pay_by_link',
            },
          );
        }

        return paymentUrl;
      } else {
        throw Exception(_extractError(response));
      }
    } catch (e, s) {
      log.e('❌ Error creating appointment payment link', error: e, stackTrace: s);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VERIFICATION (used by payment_body.dart after WebView returns)
  // ─────────────────────────────────────────────────────────────────────────

  /// Check if a payment is confirmed by looking at the Firestore transaction doc.
  ///
  /// Snippe doesn't have a polling endpoint — we rely on the webhook to update
  /// Firestore. This method just reads the current Firestore status.
  /// Called after WebView returns to check if the webhook already fired.
  Future<bool> verifyTransaction(String transactionIdOrAppointmentId) async {
    try {
      // First try looking up by transaction doc directly
      final txnDoc = await _firestore
          .collection('transactions')
          .doc(transactionIdOrAppointmentId)
          .get();

      if (txnDoc.exists) {
        final status = txnDoc.data()?['status'] as String? ?? '';
        return status == 'completed';
      }

      // Fall back: look for a completed transaction with this appointmentId
      final query = await _firestore
          .collection('transactions')
          .where('appointmentId', isEqualTo: transactionIdOrAppointmentId)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e, s) {
      log.e('❌ Error verifying transaction', error: e, stackTrace: s);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Create a pending Firestore transaction doc.
  /// The Cloud Function webhook updates status → completed/failed.
  Future<void> _createTransactionDoc({
    required String docId,
    required String userId,
    required double amount,
    required String snippeReference,
    required String type,
    required String phoneNumber,
    Map<String, dynamic> extra = const {},
  }) async {
    try {
      await _firestore.collection('transactions').doc(docId).set({
        'type':            type,
        'status':          'pending',
        'userId':          userId,
        'amount':          amount,
        'currency':        'TZS',
        'snippeReference': snippeReference,  // webhook lookup uses this
        'phoneNumber':     phoneNumber,
        'createdAt':       FieldValue.serverTimestamp(),
        'initiatedAt':     FieldValue.serverTimestamp(),
        ...extra,
      });
      log.i('✅ Transaction doc: $docId  ref: $snippeReference');
    } catch (e, s) {
      log.e('❌ Failed to create transaction doc (non-fatal)', error: e, stackTrace: s);
    }
  }

  /// Format phone to 255XXXXXXXXX.
  String _formatPhoneNumber(String phone) {
    String c = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (c.startsWith('+'))   c = c.substring(1);
    if (c.startsWith('0'))   c = '255${c.substring(1)}';
    if (c.length == 9)       c = '255$c';
    if (!c.startsWith('255')) c = '255$c';
    return c;
  }

  /// Extract readable error from a failed HTTP response.
  String _extractError(http.Response response) {
    try {
      final d = jsonDecode(response.body) as Map<String, dynamic>;
      return d['message'] as String? ??
          d['error']   as String? ??
          'Payment failed (${response.statusCode})';
    } catch (_) {
      return 'Payment failed (${response.statusCode})';
    }
  }
}