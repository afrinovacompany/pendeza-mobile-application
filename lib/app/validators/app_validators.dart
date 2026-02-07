/// A utility class containing common validator functions for form fields.
///
/// This centralizes validation logic, making it reusable and easy to maintain
/// across all forms in the application.
class AppValidators {
  // Private constructor to prevent instantiation
  AppValidators._();

  /// A regular expression for validating email addresses.
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// A regular expression for validating passwords.
  /// Requires at least 8 characters, one uppercase letter, one lowercase letter,
  /// one number, and one special character.
  static final RegExp _passwordRegExp = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  /// Validates that a value is not empty.
  ///
  /// [value] - The string to validate.
  /// [message] - An optional custom error message.
  /// Returns null if the value is valid, otherwise returns the error message.
  static String? notEmpty(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'This field cannot be empty';
    }
    return null;
  }

  /// Validates an email address.
  ///
  /// [value] - The email string to validate.
  /// Returns null if the email is valid, otherwise returns an error message.
  static String? email(String? value) {
    final emptyCheck = notEmpty(value, message: 'Please enter an email address');
    if (emptyCheck != null) {
      return emptyCheck;
    }
    if (!_emailRegExp.hasMatch(value!)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates a password based on complexity rules.
  ///
  /// [value] - The password string to validate.
  /// Returns null if the password is valid, otherwise returns an error message.
  static String? password(String? value) {
    final emptyCheck = notEmpty(value, message: 'Please enter a password');
    if (emptyCheck != null) {
      return emptyCheck;
    }
    if (value!.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!_passwordRegExp.hasMatch(value)) {
      return 'Password must contain an uppercase, lowercase, number, and special character';
    }
    return null;
  }

  /// Validates that two values match (e.g., for "Confirm Password" fields).
  ///
  /// [value1] - The first value.
  /// [value2] - The second value.
  /// Returns null if the values match, otherwise returns an error message.
  static String? valuesMatch(String? value1, String? value2, {String? message}) {
    if (value1 != value2) {
      return message ?? 'The values do not match';
    }
    return null;
  }

  /// Validates a phone number.
  /// Enhanced for Tanzanian numbers (9 digits starting with 6 or 7)
  static String? phone(String? value, {String? message}) {
    final emptyCheck = notEmpty(value, message: 'Please enter a phone number');
    if (emptyCheck != null) {
      return emptyCheck;
    }

    // Remove spaces and any non-digit characters
    final digitsOnly = value!.replaceAll(RegExp(r'\D'), '');

    // Check for Tanzanian format (9 digits starting with 6 or 7)
    if (digitsOnly.length == 9) {
      if (digitsOnly.startsWith('6') || digitsOnly.startsWith('7')) {
        return null; // Valid Tanzanian number
      } else {
        return 'Phone number must start with 6 or 7';
      }
    }

    // Fallback for other formats (10-13 digits with country code)
    if (digitsOnly.length >= 10 && digitsOnly.length <= 13) {
      return null;
    }

    return message ?? 'Please enter a valid phone number (9 digits)';
  }

  /// Validates specifically Tanzanian phone numbers
  /// Expects 9 digits starting with 6 or 7
  static String? tanzanianPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length != 9) {
      return 'Phone number must be 9 digits';
    }

    if (!digitsOnly.startsWith('6') && !digitsOnly.startsWith('7')) {
      return 'Phone number must start with 6 or 7';
    }

    return null;
  }
}