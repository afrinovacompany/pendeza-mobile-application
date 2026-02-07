import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Video approval status for admin moderation
enum VideoApprovalStatus {
  pending,   // Waiting for admin review
  approved,  // Visible to clients
  rejected,  // Not visible, owner notified
}

/// Model for salon video shorts
/// 
/// Features:
/// - 60 second max duration
/// - Auto-generated thumbnail
/// - Admin approval workflow
/// - Auto-delete after rejection/expiry
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
  final DateTime? approvedAt;
  final DateTime? expiresAt;      // For auto-delete (e.g., 30 days after approval)
  
  //============================================================================
  // MODERATION
  //============================================================================
  final VideoApprovalStatus status;
  final String? rejectionReason;  // If rejected by admin
  
  //============================================================================
  // OWNER INFO (for admin panel)
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
    this.approvedAt,
    this.expiresAt,
    this.status = VideoApprovalStatus.pending,
    this.rejectionReason,
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
      approvedAt: data['approvedAt'] != null 
          ? _parseDateTime(data['approvedAt']) 
          : null,
      expiresAt: data['expiresAt'] != null 
          ? _parseDateTime(data['expiresAt']) 
          : null,
      status: _parseStatus(data['status']),
      rejectionReason: data['rejectionReason'] as String?,
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
      approvedAt: data['approvedAt'] != null 
          ? _parseDateTime(data['approvedAt']) 
          : null,
      expiresAt: data['expiresAt'] != null 
          ? _parseDateTime(data['expiresAt']) 
          : null,
      status: _parseStatus(data['status']),
      rejectionReason: data['rejectionReason'] as String?,
      ownerId: data['ownerId'] as String,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static VideoApprovalStatus _parseStatus(dynamic value) {
    if (value == null) return VideoApprovalStatus.pending;
    final statusStr = value.toString().toLowerCase();
    switch (statusStr) {
      case 'approved':
        return VideoApprovalStatus.approved;
      case 'rejected':
        return VideoApprovalStatus.rejected;
      default:
        return VideoApprovalStatus.pending;
    }
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
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      'status': status.name,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'ownerId': ownerId,
    };
  }

  //============================================================================
  // HELPER GETTERS
  //============================================================================

  /// Check if video is visible to clients
  bool get isApproved => status == VideoApprovalStatus.approved;

  /// Check if video is pending review
  bool get isPending => status == VideoApprovalStatus.pending;

  /// Check if video was rejected
  bool get isRejected => status == VideoApprovalStatus.rejected;

  /// Check if video has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if video should be shown to clients
  bool get isVisibleToClients => isApproved && !isExpired;

  /// Get formatted duration (e.g., "0:45")
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get status display text
  String get statusText {
    switch (status) {
      case VideoApprovalStatus.pending:
        return 'Pending Review';
      case VideoApprovalStatus.approved:
        return 'Live';
      case VideoApprovalStatus.rejected:
        return 'Rejected';
    }
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
    DateTime? approvedAt,
    DateTime? expiresAt,
    VideoApprovalStatus? status,
    String? rejectionReason,
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
      approvedAt: approvedAt ?? this.approvedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
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
    approvedAt,
    expiresAt,
    status,
    rejectionReason,
    ownerId,
  ];
}
