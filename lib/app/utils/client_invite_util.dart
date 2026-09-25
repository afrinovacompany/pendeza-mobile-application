import 'package:share_plus/share_plus.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/app/services/analytics_service.dart';
import 'package:pendeza/shared/models/salon_model.dart';

class ClientInviteUtil {
  static const String playStoreLink =
      'https://play.google.com/store/apps/details?id=com.bpsa.pendeza';

  /// Triggers the native share sheet with a pre-filled invitation message
  static Future<void> inviteClient({
    required SalonModel salon,
    required AnalyticsService analytics,
  }) async {
    try {
      final String message = _buildInviteMessage(salon.salonName);

      log.i('Opening share sheet for salon: ${salon.salonName}');

      // Log the event for business insights
      await analytics.logEvent(
        name: 'salon_invite_initiated',
        parameters: {
          'salon_id': salon.id,
          'salon_name': salon.salonName,
        },
      );

      // Trigger Native Share Sheet
      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: 'Book with ${salon.salonName} on Pendeza',
        ),
      );

    } catch (e, s) {
      log.e('Failed to open share sheet', error: e, stackTrace: s);
    }
  }

  static String _buildInviteMessage(String salonName) {
    return 'Hi! This is $salonName. We are now using the Pendeza app to make booking your '
        'appointments easier. Download it here to see our services and book your next visit: '
        '\n\n$playStoreLink';
  }
}