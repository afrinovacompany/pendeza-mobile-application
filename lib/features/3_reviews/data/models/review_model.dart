import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Enhanced Review Model with owner reply and verification support.
///
/// This model stores:
/// - User's rating and comment
/// - Owner's reply (if any)
/// - Verification status (did user actually book this salon?)
/// - Timestamps for tracking
class ReviewModel extends Equatable {
  /// Unique identifier for this review
  final String id;

  /// The ID of the salon being reviewed
  final String salonId;

  /// The ID of the user who wrote this review
  final String userId;

  /// The name of the user (for display purposes)
  final String userName;

  /// Optional profile picture URL of the reviewer
  final String? userProfilePicture;

  /// Rating from 1.0 to 5.0 (stored as double for flexibility)
  final double rating;

  /// The written review comment
  final String comment;

  /// When this review was created
  final DateTime createdAt;

  /// When this review was last updated (for edits)
  final DateTime? updatedAt;

  /// Is this review from a verified booking? (user completed appointment)
  final bool isVerifiedBooking;

  /// The appointment ID that this review is for (if verified)
  final String? appointmentId;

  /// --- OWNER REPLY FIELDS ---

  /// Owner's reply to this review (nullable - may not have replied yet)
  final String? ownerReply;

  /// When the owner replied
  final DateTime? ownerRepliedAt;

  /// The owner's user ID (for verification)
  final String? ownerUserId;

  /// --- HELPFUL VOTING (for future feature) ---

  /// Number of users who found this review helpful
  final int helpfulCount;

  const ReviewModel({
    required this.id,
    required this.salonId,
    required this.userId,
    required this.userName,
    this.userProfilePicture,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    this.isVerifiedBooking = false,
    this.appointmentId,
    this.ownerReply,
    this.ownerRepliedAt,
    this.ownerUserId,
    this.helpfulCount = 0,
  });

  @override
  List<Object?> get props => [
    id,
    salonId,
    userId,
    userName,
    userProfilePicture,
    rating,
    comment,
    createdAt,
    updatedAt,
    isVerifiedBooking,
    appointmentId,
    ownerReply,
    ownerRepliedAt,
    ownerUserId,
    helpfulCount,
  ];

  /// Check if owner has replied to this review
  bool get hasOwnerReply => ownerReply != null && ownerReply!.isNotEmpty;

  /// Get star count as integer (for UI display)
  int get starCount => rating.round();

  /// Check if review was edited
  bool get isEdited => updatedAt != null && updatedAt!.isAfter(createdAt);

  /// Creates a ReviewModel from a Firestore document
  factory ReviewModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ReviewModel(
      id: doc.id,
      salonId: data['salonId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Anonymous',
      userProfilePicture: data['userProfilePicture'] as String?,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String? ?? '',
      createdAt:
      (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isVerifiedBooking: data['isVerifiedBooking'] as bool? ?? false,
      appointmentId: data['appointmentId'] as String?,
      ownerReply: data['ownerReply'] as String?,
      ownerRepliedAt: data['ownerRepliedAt'] != null
          ? (data['ownerRepliedAt'] as Timestamp).toDate()
          : null,
      ownerUserId: data['ownerUserId'] as String?,
      helpfulCount: data['helpfulCount'] as int? ?? 0,
    );
  }

  /// Converts this model to a Map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      'salonId': salonId,
      'userId': userId,
      'userName': userName,
      'userProfilePicture': userProfilePicture,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isVerifiedBooking': isVerifiedBooking,
      'appointmentId': appointmentId,
      'ownerReply': ownerReply,
      'ownerRepliedAt': ownerRepliedAt != null
          ? Timestamp.fromDate(ownerRepliedAt!)
          : null,
      'ownerUserId': ownerUserId,
      'helpfulCount': helpfulCount,
    };
  }

  /// Creates a copy with updated fields
  ReviewModel copyWith({
    String? id,
    String? salonId,
    String? userId,
    String? userName,
    String? userProfilePicture,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerifiedBooking,
    String? appointmentId,
    String? ownerReply,
    DateTime? ownerRepliedAt,
    String? ownerUserId,
    int? helpfulCount,
    bool clearOwnerReply = false,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      salonId: salonId ?? this.salonId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePicture: userProfilePicture ?? this.userProfilePicture,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerifiedBooking: isVerifiedBooking ?? this.isVerifiedBooking,
      appointmentId: appointmentId ?? this.appointmentId,
      ownerReply:
      clearOwnerReply ? null : (ownerReply ?? this.ownerReply),
      ownerRepliedAt: clearOwnerReply
          ? null
          : (ownerRepliedAt ?? this.ownerRepliedAt),
      ownerUserId:
      clearOwnerReply ? null : (ownerUserId ?? this.ownerUserId),
      helpfulCount: helpfulCount ?? this.helpfulCount,
    );
  }

  /// Factory to create a new review from user input
  factory ReviewModel.create({
    required String salonId,
    required String userId,
    required String userName,
    String? userProfilePicture,
    required double rating,
    required String comment,
    bool isVerifiedBooking = false,
    String? appointmentId,
  }) {
    return ReviewModel(
      id: '', // Will be set by Firestore
      salonId: salonId,
      userId: userId,
      userName: userName,
      userProfilePicture: userProfilePicture,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      isVerifiedBooking: isVerifiedBooking,
      appointmentId: appointmentId,
    );
  }
}