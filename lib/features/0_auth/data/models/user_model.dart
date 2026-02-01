import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// An enumeration for user gender to ensure type safety.
enum Gender { male, female, other, preferNotToSay }

/// Extension to convert Gender enum to/from string
extension GenderExtension on Gender {
  String get value {
    switch (this) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.other:
        return 'other';
      case Gender.preferNotToSay:
        return 'prefer_not_to_say';
    }
  }

  static Gender fromString(String value) {
    switch (value.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      case 'other':
        return Gender.other;
      case 'prefer_not_to_say':
        return Gender.preferNotToSay;
      default:
        return Gender.preferNotToSay;
    }
  }
}

/// The primary User entity for the application.
///
/// This class represents a single user's profile data, designed to be robust
/// and scalable. It includes methods for serialization/deserialization from
/// Firestore and supports immutable state updates.
///
/// NOW SUPPORTS GUEST MODE - Users can browse without authentication!
/// ENHANCED WITH USERNAME - Users have unique usernames for social features.
class UserModel extends Equatable {
  /// The unique identifier from FirebaseAuth. This is the document ID in Firestore.
  final String uid;

  /// The user's primary email address.
  final String email;

  /// The user's full name.
  final String fullName;

  /// **NEW**: The user's unique username (lowercase, no spaces).
  /// Used for mentions, profile URLs, and social features.
  final String? username;

  /// The user's phone number, may be null if signed up with email.
  final String? phoneNumber;

  /// The URL for the user's profile picture.
  final String? profilePictureUrl;

  /// The user's role ('client', 'owner', or 'admin'). Null if onboarding is not complete.
  final String? role;

  /// **NEW**: The user's selected gender for personalization.
  final Gender? gender;

  /// A list of Firebase Cloud Messaging (FCM) tokens for push notifications.
  /// A list is used to support a user being logged in on multiple devices.
  final List<String> fcmTokens;

  /// The timestamp when the user account was created.
  final DateTime createdAt;

  /// The timestamp of the last profile update.
  final DateTime? updatedAt;

  /// Whether this is a guest user (browsing without authentication)
  final bool isGuest;

  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.username,
    this.phoneNumber,
    this.profilePictureUrl,
    this.role,
    this.gender,
    required this.fcmTokens,
    required this.createdAt,
    this.updatedAt,
    this.isGuest = false, // Default to false for backward compatibility
  });

  /// Factory constructor to create a guest user for browsing
  factory UserModel.guest() {
    return UserModel(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: '',
      fullName: 'Guest',
      username: null,
      role: 'client', // Guests always browse as clients
      fcmTokens: [],
      createdAt: DateTime.now(),
      isGuest: true,
    );
  }

  /// A computed property to easily check if the user needs to select a role.
  bool get needsOnboarding => role == null && !isGuest;

  /// A computed property to check if the user is an admin.
  bool get isAdmin => role == 'admin' && !isGuest;

  /// A computed property to check if the user is authenticated (not a guest)
  bool get isAuthenticated => !isGuest;

  /// Check if user has all mandatory fields for client profile
  /// SIMPLIFIED: Only phone and gender required (username optional)
  bool get hasCompleteMandatoryFields {
    return phoneNumber != null &&
        phoneNumber!.isNotEmpty &&
        gender != null &&
        fullName.isNotEmpty &&
        fullName != 'New User';
  }

  /// Factory constructor to create a `UserModel` instance from a Firestore document.
  ///
  /// This method safely handles data extraction and type conversion, providing
  /// default values for missing fields to prevent runtime errors.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      username: data['username'] as String?, // NEW
      phoneNumber: data['phoneNumber'] as String?,
      profilePictureUrl: data['profilePictureUrl'] as String?,
      role: data['role'] as String?,
      // Safely handle the gender enum from a string in Firestore
      gender: data['gender'] != null
          ? GenderExtension.fromString(data['gender'] as String)
          : null,
      // Ensure fcmTokens is always a list of strings
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
      // Safely convert Firestore Timestamp to DateTime
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isGuest: false, // Firestore users are never guests
    );
  }

  /// Converts the `UserModel` instance into a `Map` for writing to Firestore.
  ///
  /// This method handles converting enums and DateTimes back to Firestore-compatible types.
  Map<String, dynamic> toFirestore() {
    return {
      // We don't write the uid to the document body, as it's the document ID.
      'email': email,
      'fullName': fullName,
      'username': username, // NEW
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'role': role,
      // Store the gender enum as a simple string
      'gender': gender?.value,
      'fcmTokens': fcmTokens,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      // isGuest is never stored in Firestore - it's a client-only flag
    };
  }

  /// Creates a copy of the current `UserModel` instance with updated fields.
  ///
  /// This is essential for working with immutable state in BLoC, allowing for
  /// predictable state changes.
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? username,
    String? phoneNumber,
    String? profilePictureUrl,
    String? role,
    Gender? gender,
    List<String>? fcmTokens,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isGuest,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    fullName,
    username,
    phoneNumber,
    profilePictureUrl,
    role,
    gender,
    fcmTokens,
    createdAt,
    updatedAt,
    isGuest,
  ];
}