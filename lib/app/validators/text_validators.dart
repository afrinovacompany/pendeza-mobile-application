import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class for text validation and normalization.
///
/// Provides methods for validating and normalizing user inputs,
/// especially for usernames and names.
class TextValidators {
  /// Converts name to lowercase and trims whitespace
  ///
  /// Example:
  /// ```dart
  /// normalizeFullName("  Juma Saidi  ") "
  /// ```
  static String normalizeFullName(String name) {
    return name.trim().toLowerCase();
  }

  /// Creates username: lowercase, no spaces, alphanumeric + underscore only
  ///
  /// Examples:
  /// ```dart
  /// normalizeUsername("John_Doe") // Returns "juma kim"
  /// normalizeUsername("john@doe") // Returns "jobek mike"
  /// normalizeUsername("John Doe 123") // Returns "juma234"
  /// ```
  static String normalizeUsername(String username) {
    return username
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), ''); // Keep only letters, numbers, underscore
  }

  /// Validates username format
  ///
  /// Rules:
  /// - Required (not null or empty)
  /// - At least 3 characters
  /// - Maximum 20 characters
  /// - Only lowercase letters, numbers, and underscore
  ///
  /// Returns error message if invalid, null if valid.
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    final normalized = normalizeUsername(value);

    if (normalized.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (normalized.length > 20) {
      return 'Username must be less than 20 characters';
    }

    // Check if it only contains valid characters
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(normalized)) {
      return 'Username can only contain lowercase letters, numbers, and underscore';
    }

    // Check if username starts with a letter (optional but recommended)
    if (!RegExp(r'^[a-z]').hasMatch(normalized)) {
      return 'Username must start with a letter';
    }

    return null; // Valid
  }

  /// Check if username is unique in Firestore
  ///
  /// Returns true if username is available, false if taken.
  ///
  /// Usage:
  /// ```dart
  /// final isUnique = await TextValidators.isUsernameUnique('john_doe');
  /// if (!isUnique) {
  ///   print('Username already taken');
  /// }
  /// ```
  static Future<bool> isUsernameUnique(String username) async {
    try {
      final normalized = normalizeUsername(username);
      
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: normalized)
          .limit(1)
          .get();

      return query.docs.isEmpty; // Returns true if no user found (unique)
    } catch (e) {
      // If there's an error checking, assume it's not unique (safe approach)
      return false;
    }
  }

  /// Validates full name
  ///
  /// Rules:
  /// - Required (not null or empty)
  /// - At least 2 characters
  /// - Only letters and spaces
  ///
  /// Returns error message if invalid, null if valid.
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }

    final trimmed = value.trim();

    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (trimmed.length > 50) {
      return 'Name must be less than 50 characters';
    }

    // Check if it only contains letters, spaces, and common name characters
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(trimmed)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null; // Valid
  }

  /// Validates email format
  ///
  /// Basic email validation using regex.
  /// Returns error message if invalid, null if valid.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null; // Valid
  }

  /// Validates phone number format (basic)
  ///
  /// Accepts formats like:
  /// - +255712345678
  /// - 0712345678
  /// - 255712345678
  ///
  /// Returns error message if invalid, null if valid.
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces and dashes for validation
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');

    // Check if it's a valid format
    if (!RegExp(r'^\+?[0-9]{10,13}$').hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }

    return null; // Valid
  }

  /// Validates salon name
  ///
  /// Rules:
  /// - Required (not null or empty)
  /// - At least 3 characters
  /// - Maximum 50 characters
  ///
  /// Returns error message if invalid, null if valid.
  static String? validateSalonName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Salon name is required';
    }

    final trimmed = value.trim();

    if (trimmed.length < 3) {
      return 'Salon name must be at least 3 characters';
    }

    if (trimmed.length > 50) {
      return 'Salon name must be less than 50 characters';
    }

    return null; // Valid
  }

  /// Validates address
  ///
  /// Rules:
  /// - Required (not null or empty)
  /// - At least 5 characters
  ///
  /// Returns error message if invalid, null if valid.
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }

    final trimmed = value.trim();

    if (trimmed.length < 5) {
      return 'Please enter a complete address';
    }

    return null; // Valid
  }

  /// Generates a username suggestion from a full name
  ///
  /// Example:
  /// ```dart
  /// suggestUsername("John Doe") // Returns "john_doe"
  /// suggestUsername("Mary Jane Watson") // Returns "mary_watson"
  /// ```
  static String suggestUsername(String fullName) {
    final parts = fullName.trim().toLowerCase().split(' ');
    
    if (parts.isEmpty) return '';
    if (parts.length == 1) return normalizeUsername(parts[0]);
    
    // Use first name + last name
    final suggestion = '${parts.first}_${parts.last}';
    return normalizeUsername(suggestion);
  }

  /// Generates alternative username suggestions if the original is taken
  ///
  /// Example:
  /// ```dart
  /// generateAlternatives("john_doe") 
  /// // Returns ["john_doe1", "john_doe2", "john_doe123"]
  /// ```
  static List<String> generateAlternatives(String username) {
    final normalized = normalizeUsername(username);
    return [
      '${normalized}1',
      '${normalized}2',
      '${normalized}123',
      '${normalized}_tz',
      '${normalized}_',
    ];
  }
}
