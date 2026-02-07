/// Environment Configuration for sensitive API credentials
///
/// IMPORTANT: This file contains production credentials.
/// - DO NOT commit real credentials to version control
/// - Use environment variables or secure storage in CI/CD
/// - For local development, update values here but don't commit
///
/// For App Store submission: These values should be injected at build time
/// using --dart-define or a secrets management system.
class EnvConfig {
  // PalmPesa Payment Gateway Configuration
  static const String palmPesaBaseUrl = String.fromEnvironment(
    'PALMPESA_BASE_URL',
    defaultValue: 'https://palmpesa.drmlelwa.co.tz/api',
  );

  static const String palmPesaApiToken = String.fromEnvironment(
    'PALMPESA_API_TOKEN',
    defaultValue: 'xW89Ys1pb3h0x2n3YgUjeRFdMocYC0fqWYN7qKyFhEgil6qEuuBWZ3gnxoZ2',
  );

  static const int palmPesaUserId = int.fromEnvironment(
    'PALMPESA_USER_ID',
    defaultValue: 21,
  );

  static const String palmPesaVendorId = String.fromEnvironment(
    'PALMPESA_VENDOR_ID',
    defaultValue: 'TILL61103867',
  );

  // Webhook Configuration
  static const String paymentWebhookUrl = String.fromEnvironment(
    'PAYMENT_WEBHOOK_URL',
    defaultValue: 'https://on-payment-webhook-n6kcpecbaa-uc.a.run.app',
  );

  // Payment Redirect URLs
  static const String paymentSuccessUrl = String.fromEnvironment(
    'PAYMENT_SUCCESS_URL',
    defaultValue: 'https://pendeza.app/payment-success',
  );

  static const String paymentCancelUrl = String.fromEnvironment(
    'PAYMENT_CANCEL_URL',
    defaultValue: 'https://pendeza.app/payment-cancel',
  );

  // Fallback email for payments
  static const String fallbackEmail = 'agentbfs@gmail.com';
}
