import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model for salon video shorts
///
/// Features:
/// - 60 second max duration
/// - Auto-generated thumbnail
/// - Immediately visible after upload (no approval needed)
class SalonVideoModel extends Equatable {
  //============================================================================
  // CORE FIELDS
  //============================================================================
  final String id;
  final String salonId;

  /// Denormalized salon data for fast queries (no extra reads)
  final String salonName;
  final String? salonImage;
  final String? salonAddress;

  //============================================================================
  // VIDEO DATA
  //============================================================================
  final String videoUrl;
  final String thumbnailUrl;      // Auto-generated from first frame
  final String? caption;          // Optional short description
  final int durationSeconds;      // Max 60 seconds

  //============================================================================
  // TIMESTAMPS
  //============================================================================
  final DateTime createdAt;

  //============================================================================
  // OWNER INFO
  //============================================================================
  final String ownerId;

  const SalonVideoModel({
    required this.id,
    required this.salonId,
    required this.salonName,
    this.salonImage,
    this.salonAddress,
    required this.videoUrl,
    required this.thumbnailUrl,
    this.caption,
    required this.durationSeconds,
    required this.createdAt,
    required this.ownerId,
  });

  //============================================================================
  // FACTORY CONSTRUCTORS
  //============================================================================

  factory SalonVideoModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SalonVideoModel(
      id: doc.id,
      salonId: data['salonId'] as String,
      salonName: data['salonName'] as String,
      salonImage: data['salonImage'] as String?,
      salonAddress: data['salonAddress'] as String?,
      videoUrl: data['videoUrl'] as String,
      thumbnailUrl: data['thumbnailUrl'] as String,
      caption: data['caption'] as String?,
      durationSeconds: data['durationSeconds'] as int? ?? 0,
      createdAt: _parseDateTime(data['createdAt']),
      ownerId: data['ownerId'] as String,
    );
  }

  /// Create from Map (useful for queries)
  factory SalonVideoModel.fromMap(Map<String, dynamic> data, String id) {
    return SalonVideoModel(
      id: id,
      salonId: data['salonId'] as String,
      salonName: data['salonName'] as String,
      salonImage: data['salonImage'] as String?,
      salonAddress: data['salonAddress'] as String?,
      videoUrl: data['videoUrl'] as String,
      thumbnailUrl: data['thumbnailUrl'] as String,
      caption: data['caption'] as String?,
      durationSeconds: data['durationSeconds'] as int? ?? 0,
      createdAt: _parseDateTime(data['createdAt']),
      ownerId: data['ownerId'] as String,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }

  //============================================================================
  // TO FIRESTORE
  //============================================================================

  Map<String, dynamic> toFirestore() {
    return {
      'salonId': salonId,
      'salonName': salonName,
      if (salonImage != null) 'salonImage': salonImage,
      if (salonAddress != null) 'salonAddress': salonAddress,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      if (caption != null) 'caption': caption,
      'durationSeconds': durationSeconds,
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerId': ownerId,
    };
  }

  //============================================================================
  // HELPER GETTERS
  //============================================================================

  /// Get formatted duration (e.g., "0:45")
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  //============================================================================
  // COPY WITH
  //============================================================================

  SalonVideoModel copyWith({
    String? id,
    String? salonId,
    String? salonName,
    String? salonImage,
    String? salonAddress,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    int? durationSeconds,
    DateTime? createdAt,
    String? ownerId,
  }) {
    return SalonVideoModel(
      id: id ?? this.id,
      salonId: salonId ?? this.salonId,
      salonName: salonName ?? this.salonName,
      salonImage: salonImage ?? this.salonImage,
      salonAddress: salonAddress ?? this.salonAddress,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  //============================================================================
  // EQUATABLE
  //============================================================================

  @override
  List<Object?> get props => [
    id,
    salonId,
    salonName,
    salonImage,
    salonAddress,
    videoUrl,
    thumbnailUrl,
    caption,
    durationSeconds,
    createdAt,
    ownerId,
  ];
}
