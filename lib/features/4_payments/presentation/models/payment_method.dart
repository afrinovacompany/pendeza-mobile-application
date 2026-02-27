// =============================================================================
// Payment Method Enum
// =============================================================================
// Defines available payment methods in the app.
// =============================================================================

import 'package:flutter/material.dart';

/// Available payment methods
enum PaymentMethod {
  /// Pay from wallet balance (instant)
  wallet,

  /// Mobile Payment - sends payment prompt to phone (M-Pesa, Tigo Pesa, etc.)
  mobileMoney,

  /// Pay by Card - redirects to card payment page
  payByLink,
}

/// Extension methods for PaymentMethod
extension PaymentMethodExtension on PaymentMethod {
  /// Human-readable title
  String get title {
    switch (this) {
      case PaymentMethod.wallet:
        return 'Pay from Wallet';
      case PaymentMethod.mobileMoney:
        return 'Mobile Payment';
      case PaymentMethod.payByLink:
        return 'Pay by Card';
    }
  }

  /// Description text
  String get subtitle {
    switch (this) {
      case PaymentMethod.wallet:
        return 'Instant payment from your balance';
      case PaymentMethod.mobileMoney:
        return 'M-Pesa, Tigo Pesa, Airtel Money';
      case PaymentMethod.payByLink:
        return 'Pay with debit or credit card';
    }
  }

  /// Info message shown when method is selected
  String get infoMessage {
    switch (this) {
      case PaymentMethod.wallet:
        return 'Money will be deducted from your wallet instantly.';
      case PaymentMethod.mobileMoney:
        return 'A payment prompt will be sent to your phone. Enter your mobile money PIN to confirm.';
      case PaymentMethod.payByLink:
        return "You'll be redirected to a secure card payment page.";
    }
  }

  /// Icon for the payment method
  IconData get icon {
    switch (this) {
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet_rounded;
      case PaymentMethod.mobileMoney:
        return Icons.phone_android_rounded;
      case PaymentMethod.payByLink:
        return Icons.credit_card_rounded;
    }
  }

  /// Whether this method requires a phone number input
  bool get requiresPhoneNumber {
    return this != PaymentMethod.wallet;
  }
}
