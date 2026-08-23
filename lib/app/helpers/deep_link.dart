import 'package:app_links/app_links.dart';
import '../config/app_router.dart';
import '../utils/logger.dart';

class DeepLinkService {
  final _appLinks = AppLinks();

  // Singleton
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  Future<void> init() async {
    // Handle initial link (app opened via link)
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink);
    }

    // Listen to incoming links (app already running)
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    log.i('Deep link received: $uri');

    // Example: pendeza://salon/abc123
    // Example: https://pendeza.app/salon/abc123

    final path = uri.path;
    final segments = uri.pathSegments;

    if (segments.isEmpty) return;

    final router = AppRouter.router;

    switch (segments[0]) {
      case 'salon':
        if (segments.length >= 2) {
          final salonId = segments[1];
          router.push('/salon/$salonId');
        }
        break;

      case 'promotion':
        if (segments.length >= 2) {
          final promoId = segments[1];
          // Navigate to promotion detail or apply promo
          log.i('Promo deep link: $promoId');
        }
        break;

      case 'booking':
        if (segments.length >= 2) {
          final bookingId = segments[1];
          log.i('Booking deep link: $bookingId');
          router.push('/client/bookings');
        }
        break;

      case 'referral':
        final referralCode = uri.queryParameters['code'];
        if (referralCode != null) {
          // Store referral code, apply on signup
          log.i('Referral code: $referralCode');
        }
        break;

      default:
        log.w('Unknown deep link path: $path');
    }
  }
}

// Android setup (android/app/src/main/AndroidManifest.xml):
// <intent-filter>
//   <action android:name="android.intent.action.VIEW" />
//   <category android:name="android.intent.category.DEFAULT" />
//   <category android:name="android.intent.category.BROWSABLE" />
//   <data android:scheme="pendeza" />
//   <data android:host="pendeza.app" android:scheme="https" />
// </intent-filter>

// iOS setup (ios/Runner/Info.plist):
// <key>CFBundleURLTypes</key>
// <array>
//   <dict>
//     <key>CFBundleURLSchemes</key>
//     <array>
//       <string>pendeza</string>
//     </array>
//   </dict>
// </array>