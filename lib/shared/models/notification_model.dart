import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Types of notifications
enum NotificationType {
  appointment,
  promotion,
  system,
  payment,
  review,
  general,
}

/// Model for user notifications
///
/// Supports both:
/// - Personal notifications (from 'notifications' collection)
/// - Broadcast notifications (from 'notification_inbox' collection)
class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;

  // Enhanced fields
  final String? imageUrl;
  final String? actionRoute;
  final String? actionLabel;
  final Map<String, dynamic>? data;

  // Broadcast support
  final bool isBroadcast; // true = from notification_inbox, false = personal

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.imageUrl,
    this.actionRoute,
    this.actionLabel,
    this.data,
    this.isBroadcast = false,
  });

  /// Create from Firestore document (personal notifications)
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromMap(data, doc.id);
  }

  /// Create from map (personal notifications)
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? 'Notification',
      body: map['body'] as String? ?? '',
      type: _parseType(map['type']),
      createdAt: _parseDateTime(map['createdAt']),
      isRead: map['isRead'] as bool? ?? false,
      readAt: map['readAt'] != null ? _parseDateTime(map['readAt']) : null,
      imageUrl: map['imageUrl'] as String?,
      actionRoute: map['actionRoute'] as String?,
      actionLabel: map['actionLabel'] as String?,
      data: map['data'] as Map<String, dynamic>?,
      isBroadcast: false,
    );
  }

  /// Create from notification_inbox document (broadcast notifications)
  /// These have different field names: sentAt instead of createdAt,
  /// route instead of actionRoute, no userId, etc.
  factory NotificationModel.fromBroadcast(
      DocumentSnapshot doc, {
        required String currentUserId,
        required bool isRead,
      }) {
    final data = doc.data() as Map<String, dynamic>;

    // Extract route from customData or top-level
    String? route = data['route'] as String?;
    if (route == null || route.isEmpty) {
      final customData = data['customData'] as Map<String, dynamic>?;
      route = customData?['route'] as String?;
    }

    // Extract actionLabel from customData
    String? actionLabel;
    final customData = data['customData'] as Map<String, dynamic>?;
    actionLabel = customData?['actionLabel'] as String?;

    return NotificationModel(
      id: 'broadcast_${doc.id}', // Prefix to avoid ID collision with personal
      userId: currentUserId,
      title: data['title'] as String? ?? 'Announcement',
      body: data['body'] as String? ?? '',
      type: _parseType(data['type']),
      createdAt: _parseDateTime(data['sentAt']),
      isRead: isRead,
      imageUrl: data['imageUrl'] as String?,
      actionRoute: route,
      actionLabel: actionLabel,
      data: customData,
      isBroadcast: true,
    );
  }

  /// The real Firestore document ID (without broadcast_ prefix)
  String get firestoreId {
    if (isBroadcast && id.startsWith('broadcast_')) {
      return id.substring('broadcast_'.length);
    }
    return id;
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      if (readAt != null) 'readAt': Timestamp.fromDate(readAt!),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (actionRoute != null) 'actionRoute': actionRoute,
      if (actionLabel != null) 'actionLabel': actionLabel,
      if (data != null) 'data': data,
    };
  }

  /// Parse notification type from string
  static NotificationType _parseType(dynamic value) {
    if (value == null) return NotificationType.general;

    final typeStr = value.toString().toLowerCase();
    switch (typeStr) {
      case 'appointment':
        return NotificationType.appointment;
      case 'promotion':
      case 'promotional':
        return NotificationType.promotion;
      case 'system':
        return NotificationType.system;
      case 'payment':
        return NotificationType.payment;
      case 'review':
        return NotificationType.review;
      default:
        return NotificationType.general;
    }
  }

  /// Parse datetime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  /// Get human-readable time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1 ? '1 day ago' : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 ? '1 hour ago' : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 ? '1 minute ago' : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if notification has a call-to-action
  bool get hasAction => actionRoute != null && actionRoute!.isNotEmpty;

  /// Check if notification has an image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Copy with
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    String? imageUrl,
    String? actionRoute,
    String? actionLabel,
    Map<String, dynamic>? data,
    bool? isBroadcast,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      imageUrl: imageUrl ?? this.imageUrl,
      actionRoute: actionRoute ?? this.actionRoute,
      actionLabel: actionLabel ?? this.actionLabel,
      data: data ?? this.data,
      isBroadcast: isBroadcast ?? this.isBroadcast,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    body,
    type,
    createdAt,
    isRead,
    readAt,
    imageUrl,
    actionRoute,
    actionLabel,
    data,
    isBroadcast,
  ];
}