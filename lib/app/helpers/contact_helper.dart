import 'package:url_launcher/url_launcher.dart';
import 'package:pendeza/app/utils/logger.dart';

/// Utility to handle external communications (WhatsApp, Phone).
/// Replaces the generic map directions with direct owner contact.
class ContactHelper {
  ContactHelper._();

  /// Launches WhatsApp with a pre-filled context message.
  ///
  /// [phone]: The salon's phone number (e.g., "+255712...").
  /// [message]: The pre-filled text (e.g., "Hi, I want to book...").
  static Future<void> openWhatsApp({
    required String phone,
    String? message,
  }) async {
    try {
      // 1. Sanitize the phone number (remove spaces, dashes, parentheses)
      // Keep only digits.
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

      // 2. Encode the message for URL safety
      final encodedMessage = message != null
          ? Uri.encodeComponent(message)
          : '';

      // 3. Construct the Universal WhatsApp URL
      // This works on both Android and iOS without needing specific package schemes
      final url = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

      // 4. Launch logic
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        log.w('Could not launch WhatsApp for $cleanPhone. Fallback to dialer.');
        // Fallback: If WhatsApp isn't installed, open the phone dialer
        makePhoneCall(phone);
      }
    } catch (e) {
      log.e('Error launching WhatsApp', error: e);
    }
  }

  /// Launches the device's standard phone dialer.
  static Future<void> makePhoneCall(String phone) async {
    try {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phone,
      );
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        log.w('Could not launch dialer for $phone');
      }
    } catch (e) {
      log.e('Error making phone call', error: e);
    }
  }

  /// Generates a professional pre-filled message for general inquiries.
  static String createInquiryMessage({
    required String salonName,
    String? serviceName,
  }) {
    if (serviceName != null) {
      return "Hi $salonName! 👋 I saw your $serviceName service on Pendeza and I have a question.";
    }
    return "Hi $salonName! 👋 I found you on Pendeza and would like to make an inquiry.";
  }

  /// Generates a pre-filled message for booking confirmation/directions.
  static String createBookingMessage({
    required String salonName,
    required String date,
    required String time,
  }) {
    return "Hi $salonName! 👋 I have a booking on $date at $time. I'd like to confirm the location details.";
  }
}