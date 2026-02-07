import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a user's favorite salon.
///
/// This model tracks when a salon was favorited and can be extended
/// with additional metadata like tags, notes, or reminders.
class FavoriteModel extends Equatable {
  /// The user ID who favorited this salon
  final String userId;

  /// The salon ID that was favorited
  final String salonId;

  /// When this salon was added to favorites
  final DateTime favoritedAt;

  /// Optional: User's personal note about this salon
  final String? note;

  /// Optional: User's personal tags (e.g., "wedding", "date night")
  final List<String>? tags;

  const FavoriteModel({
    required this.userId,
    required this.salonId,
    required this.favoritedAt,
    this.note,
    this.tags,
  });

  @override
  List<Object?> get props => [
    userId,
    salonId,
    favoritedAt,
    note,
    tags,
  ];

  /// Creates a FavoriteModel from a Firestore document
  factory FavoriteModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FavoriteModel(
      userId: data['userId'] as String? ?? '',
      salonId: data['salonId'] as String? ?? '',
      favoritedAt:
      (data['favoritedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      note: data['note'] as String?,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
    );
  }

  /// Converts this model to a Map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'salonId': salonId,
      'favoritedAt': Timestamp.fromDate(favoritedAt),
      if (note != null) 'note': note,
      if (tags != null) 'tags': tags,
    };
  }

  /// Creates a copy with updated fields
  FavoriteModel copyWith({
    String? userId,
    String? salonId,
    DateTime? favoritedAt,
    String? note,
    List<String>? tags,
    bool clearNote = false,
    bool clearTags = false,
  }) {
    return FavoriteModel(
      userId: userId ?? this.userId,
      salonId: salonId ?? this.salonId,
      favoritedAt: favoritedAt ?? this.favoritedAt,
      note: clearNote ? null : (note ?? this.note),
      tags: clearTags ? null : (tags ?? this.tags),
    );
  }

  /// Create a simple favorite (just userId + salonId)
  factory FavoriteModel.simple({
    required String userId,
    required String salonId,
  }) {
    return FavoriteModel(
      userId: userId,
      salonId: salonId,
      favoritedAt: DateTime.now(),
    );
  }
}