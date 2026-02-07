// =============================================================================
// Payment Method Enum
// =============================================================================
// Defines available payment methods in the app.
// =============================================================================

/// Available payment methods
enum PaymentMethod {
  /// Pay from wallet balance (instant)
  wallet,

  /// USSD Push - sends payment prompt to phone
  ussdPush,

  /// Pay by Link - redirects to web payment page
  payByLink,
}

/// Extension methods for PaymentMethod
extension PaymentMethodExtension on PaymentMethod {
  /// Human-readable title
  String get title {
    switch (this) {
      case PaymentMethod.wallet:
        return 'Pay from Wallet';
      case PaymentMethod.ussdPush:
        return 'USSD Push';
      case PaymentMethod.payByLink:
        return 'Pay by Link';
    }
  }

  /// Description text
  String get subtitle {
    switch (this) {
      case PaymentMethod.wallet:
        return 'Instant payment from your balance';
      case PaymentMethod.ussdPush:
        return 'Receive instant payment prompt on phone';
      case PaymentMethod.payByLink:
        return 'Complete payment in browser';
    }
  }

  /// Info message shown when method is selected
  String get infoMessage {
    switch (this) {
      case PaymentMethod.wallet:
        return 'Money will be deducted from your wallet instantly.';
      case PaymentMethod.ussdPush:
        return 'You will receive a payment request on your phone.';
      case PaymentMethod.payByLink:
        return "You'll be redirected to a secure payment page.";
    }
  }

  /// Whether this method requires a phone number input
  bool get requiresPhoneNumber {
    return this != PaymentMethod.wallet;
  }
}