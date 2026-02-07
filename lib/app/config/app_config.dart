// lib/app/config/app_config.dart
class AppConfig {
  static const String deepLinkDomain = 'https://bpsa-8bde0.web.app';
  static const String appName = 'Pendeza';

  static String getSalonDeepLink(String salonId) {
    return '$deepLinkDomain/salon/$salonId';
  }
}