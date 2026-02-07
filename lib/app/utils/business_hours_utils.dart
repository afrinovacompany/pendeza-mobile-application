import 'package:flutter/material.dart';

/// Represents the current operational status of a salon.
enum SalonStatus {
  /// Salon is currently open for business
  open,

  /// Salon is currently closed
  closed,

  /// Salon is closed but will open soon (within 1 hour)
  opening,

  /// Salon is open but will close soon (within 1 hour)
  closing,

  /// Business hours not set
  unknown,
}

/// Utility class for determining salon open/closed status based on business hours.
class BusinessHoursUtils {
  BusinessHoursUtils._();

  /// Get the current status of a salon based on opening and closing times.
  ///
  /// [openingTime] - Opening time in "HH:mm" format (e.g., "08:00")
  /// [closingTime] - Closing time in "HH:mm" format (e.g., "20:00")
  /// [currentTime] - Optional DateTime for testing, defaults to now
  static SalonStatus getStatus({
    required String? openingTime,
    required String? closingTime,
    DateTime? currentTime,
  }) {
    if (openingTime == null || closingTime == null) {
      return SalonStatus.unknown;
    }

    final now = currentTime ?? DateTime.now();

    final openTime = _parseTime(openingTime);
    final closeTime = _parseTime(closingTime);

    if (openTime == null || closeTime == null) {
      return SalonStatus.unknown;
    }

    final currentMinutes = now.hour * 60 + now.minute;
    final openMinutes = openTime.hour * 60 + openTime.minute;
    final closeMinutes = closeTime.hour * 60 + closeTime.minute;

    // Handle overnight hours (e.g., 22:00 - 06:00)
    final isOvernight = closeMinutes < openMinutes;

    bool isOpen;
    if (isOvernight) {
      // Open if current time is after opening OR before closing
      isOpen = currentMinutes >= openMinutes || currentMinutes < closeMinutes;
    } else {
      // Normal hours: open if between opening and closing
      isOpen = currentMinutes >= openMinutes && currentMinutes < closeMinutes;
    }

    if (isOpen) {
      // Check if closing soon (within 60 minutes)
      int minutesUntilClose;
      if (isOvernight && currentMinutes >= openMinutes) {
        // After midnight until closing
        minutesUntilClose = (24 * 60 - currentMinutes) + closeMinutes;
      } else {
        minutesUntilClose = closeMinutes - currentMinutes;
      }

      if (minutesUntilClose <= 60 && minutesUntilClose > 0) {
        return SalonStatus.closing;
      }
      return SalonStatus.open;
    } else {
      // Check if opening soon (within 60 minutes)
      int minutesUntilOpen;
      if (currentMinutes < openMinutes) {
        minutesUntilOpen = openMinutes - currentMinutes;
      } else {
        // After closing, calculate time until next day's opening
        minutesUntilOpen = (24 * 60 - currentMinutes) + openMinutes;
      }

      if (minutesUntilOpen <= 60) {
        return SalonStatus.opening;
      }
      return SalonStatus.closed;
    }
  }

  /// Get a human-readable status text.
  ///
  /// Returns localized strings like:
  /// - "Open Now"
  /// - "Closed"
  /// - "Opens at 9:00 AM"
  /// - "Closes at 8:00 PM"
  static String getStatusText({
    required String? openingTime,
    required String? closingTime,
    DateTime? currentTime,
  }) {
    final status = getStatus(
      openingTime: openingTime,
      closingTime: closingTime,
      currentTime: currentTime,
    );

    switch (status) {
      case SalonStatus.open:
        return 'Open Now';
      case SalonStatus.closed:
        if (openingTime != null) {
          final openTime = _parseTime(openingTime);
          if (openTime != null) {
            return 'Opens at ${_formatTime(openTime)}';
          }
        }
        return 'Closed';
      case SalonStatus.opening:
        if (openingTime != null) {
          final openTime = _parseTime(openingTime);
          if (openTime != null) {
            return 'Opens at ${_formatTime(openTime)}';
          }
        }
        return 'Opening Soon';
      case SalonStatus.closing:
        if (closingTime != null) {
          final closeTime = _parseTime(closingTime);
          if (closeTime != null) {
            return 'Closes at ${_formatTime(closeTime)}';
          }
        }
        return 'Closing Soon';
      case SalonStatus.unknown:
        return 'Hours not set';
    }
  }

  /// Get the status color based on salon status.
  ///
  /// - Green for open
  /// - Red for closed
  /// - Orange for opening/closing soon
  static Color getStatusColor(SalonStatus status) {
    switch (status) {
      case SalonStatus.open:
        return const Color(0xFF22C55E); // Green
      case SalonStatus.closed:
        return const Color(0xFFEF4444); // Red
      case SalonStatus.opening:
      case SalonStatus.closing:
        return const Color(0xFFF97316); // Orange
      case SalonStatus.unknown:
        return const Color(0xFF9CA3AF); // Grey
    }
  }

  /// Get the status color directly from opening/closing times.
  static Color getStatusColorFromTimes({
    required String? openingTime,
    required String? closingTime,
    DateTime? currentTime,
  }) {
    final status = getStatus(
      openingTime: openingTime,
      closingTime: closingTime,
      currentTime: currentTime,
    );
    return getStatusColor(status);
  }

  /// Check if salon is currently open (includes opening/closing states).
  /// Returns true if hours are not set (assume open).
  static bool isOpen({
    required String? openingTime,
    required String? closingTime,
    DateTime? currentTime,
  }) {
    final status = getStatus(
      openingTime: openingTime,
      closingTime: closingTime,
      currentTime: currentTime,
    );
    return status == SalonStatus.open || status == SalonStatus.closing || status == SalonStatus.unknown;
  }

  /// Parse time string in "HH:mm" format to TimeOfDay.
  static TimeOfDay? _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return null;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  /// Format TimeOfDay to readable string (e.g., "9:00 AM").
  static String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Format opening hours range (e.g., "9:00 AM - 8:00 PM").
  static String formatHoursRange(String? openingTime, String? closingTime) {
    if (openingTime == null || closingTime == null) {
      return 'Hours not set';
    }

    final openTime = _parseTime(openingTime);
    final closeTime = _parseTime(closingTime);

    if (openTime == null || closeTime == null) {
      return '$openingTime - $closingTime';
    }

    return '${_formatTime(openTime)} - ${_formatTime(closeTime)}';
  }
}
