
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// An enumeration for user gender to ensure type safety.
enum Gender { male, female, other, preferNotToSay }

/// The primary User entity for the application.
///
/// This class represents a single user's profile data, designed to be robust
/// and scalable. It includes methods for serialization/deserialization from
/// Firestore and supports immutable state updates.
class UserModel extends Equatable {
  /// The unique identifier from FirebaseAuth. This is the document ID in Firestore.
  final String uid;

  /// The user's primary email address.
  final String email;

  /// The user's full name.
  final String fullName;

  /// The user's phone number, may be null if signed up with email.
  final String? phoneNumber;

  /// The URL for the user's profile picture.
  final String? profilePictureUrl;

  /// The user's role ('client' or 'owner'). Null if onboarding is not complete.
  final String? role;

  /// The user's selected gender for personalization.
  final Gender? gender;

  /// A list of Firebase Cloud Messaging (FCM) tokens for push notifications.
  /// A list is used to support a user being logged in on multiple devices.
  final List<String> fcmTokens;

  /// The timestamp when the user account was created.
  final DateTime createdAt;

  /// The timestamp of the last profile update.
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.profilePictureUrl,
    this.role,
    this.gender,
    required this.fcmTokens,
    required this.createdAt,
    this.updatedAt,
  });

  /// A computed property to easily check if the user needs to select a role.
  bool get needsOnboarding => role == null;

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
      phoneNumber: data['phoneNumber'] as String?,
      profilePictureUrl: data['profilePictureUrl'] as String?,
      role: data['role'] as String?,
      // Safely handle the gender enum from a string in Firestore
      gender: data['gender'] != null
          ? Gender.values.firstWhere(
            (e) => e.toString() == 'Gender.${data['gender']}',
        orElse: () => Gender.preferNotToSay,
      )
          : null,
      // Ensure fcmTokens is always a list of strings
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
      // Safely convert Firestore Timestamp to DateTime
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'role': role,
      // Store the gender enum as a simple string
      'gender': gender?.name,
      'fcmTokens': fcmTokens,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
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
    String? phoneNumber,
    String? profilePictureUrl,
    String? role,
    Gender? gender,
    List<String>? fcmTokens,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    fullName,
    phoneNumber,
    profilePictureUrl,
    role,
    gender,
    fcmTokens,
    createdAt,
    updatedAt,
  ];
}
