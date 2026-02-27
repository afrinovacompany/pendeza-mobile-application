/// Environment Configuration for sensitive API credentials
///
/// IMPORTANT: This file contains production credentials.
/// - DO NOT commit real credentials to version control
/// - Use --dart-define to inject values at build time
///
/// Build command example:
///   flutter run \
///     --dart-define=SNIPPE_BASE_URL=https://api.snippe.sh \
///     --dart-define=SNIPPE_API_KEY=snp_live_xxxxx
class EnvConfig {
  // ── Snippe Payment Gateway ───────────────────────────────────────────────
  // IMPORTANT: Base URL is api.snippe.sh (not .com)
  static const String snippeBaseUrl = String.fromEnvironment(
    'SNIPPE_BASE_URL',
    defaultValue: 'https://api.snippe.sh',
  );

  static const String snippeApiKey = String.fromEnvironment(
    'SNIPPE_API_KEY',
    defaultValue: 'snp_f05827640ec57ab5cddf5e4eb5c8b0d4eff949d6ab972e63ec2cebee3b38cd7e',
  );

  // ── Webhook & Redirect URLs ───────────────────────────────────────────────
  static const String paymentWebhookUrl = String.fromEnvironment(
    'PAYMENT_WEBHOOK_URL',
    defaultValue: 'https://on-payment-webhook-n6kcpecbaa-uc.a.run.app',
  );

  static const String paymentSuccessUrl = String.fromEnvironment(
    'PAYMENT_SUCCESS_URL',
    defaultValue: 'https://pendeza.app/payment-success',
  );

  static const String paymentCancelUrl = String.fromEnvironment(
    'PAYMENT_CANCEL_URL',
    defaultValue: 'https://pendeza.app/payment-cancel',
  );

  // Fallback email when user has no email set
  static const String fallbackEmail = 'agentbfs@gmail.com';
}