// lib/app/config/app_config.dart
class AppConfig {
  static const String deepLinkDomain = 'https://bpsa-8bde0.web.app';
  static const String appName = 'Pendeza';

  // TEMPORARILY DISABLED - Payments turned off for App Store submission
  // Set to true to restore Snippe checkout, wallet UI, and Pay Now flows.
  static const bool paymentsEnabled = false;

  static String getSalonDeepLink(String salonId) {
    return '$deepLinkDomain/salon/$salonId';
  }
}