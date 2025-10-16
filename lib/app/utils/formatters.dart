import 'package:intl/intl.dart';

/// A utility class containing common formatter functions for the application.
///
/// This centralizes data formatting logic, ensuring that dates, currencies,
/// and other data types are displayed consistently throughout the app.
///
/// Requires the `intl` package. Add it to your pubspec.yaml:
/// dependencies:
///   intl: ^0.19.0 # or latest version
///
class AppFormatters {
  // Private constructor to prevent instantiation
  AppFormatters._();

  //============================================================================
  // DATE & TIME FORMATTERS
  //============================================================================

  /// Formatter for a full date (e.g., "Monday, 14 June 2025").
  static final DateFormat fullDate = DateFormat.yMMMMEEEEd();

  /// Formatter for a short date (e.g., "06/14/2025").
  static final DateFormat shortDate = DateFormat('MM/dd/yyyy');

  /// Formatter for a month and day (e.g., "June 14").
  static final DateFormat monthDay = DateFormat.MMMMd();

  /// Formatter for time (e.g., "3:30 PM").
  static final DateFormat timeOfDay = DateFormat.jm();

  /// Formats a DateTime object into a full date string.
  /// Returns an empty string if the date is null.
  static String formatDate(DateTime? date) {
    return date != null ? fullDate.format(date) : '';
  }

  /// Formats a DateTime object into a time string.
  /// Returns an empty string if the date is null.
  static String formatTime(DateTime? date) {
    return date != null ? timeOfDay.format(date) : '';
  }

  //============================================================================
  // CURRENCY FORMATTER
  //============================================================================

  /// Formatter for Tanzanian Shilling (TZS).
  /// Example: "TSh 5,000"
  static final NumberFormat currency = NumberFormat.currency(
    locale: 'en_TZ', // Using a locale that supports TZS formatting
    symbol: 'TSh ',   // Custom symbol
    decimalDigits: 0, // No decimal places for TZS
  );

  /// Formats a numeric value into a TZS currency string.
  static String formatCurrency(double? amount) {
    return amount != null ? currency.format(amount) : '';
  }

  //============================================================================
  // OTHER FORMATTERS
  //============================================================================

  /// Hides part of a phone number for privacy.
  /// Example: "0712345678" -> "071*****78"
  static String? partiallyHidePhone(String? phone) {
    if (phone == null || phone.length < 9) return phone;
    final start = phone.substring(0, 3);
    final end = phone.substring(phone.length - 2);
    return '$start*****$end';
  }
}
