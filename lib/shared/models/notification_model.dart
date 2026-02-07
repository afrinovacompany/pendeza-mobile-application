import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the type of notification
enum NotificationType {
  appointment,    // Booking confirmations, reminders, cancellations
  promotion,      // Special offers and discounts
  system,         // App updates, maintenance
  payment,        // Payment confirmations, refunds
  review,         // Review requests, responses
  general,        // General announcements
}

/// Model representing a notification in the app
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? imageUrl;
  final String? actionRoute;      // Route to navigate when tapped
  final Map<String, dynamic>? data; // Additional data

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.imageUrl,
    this.actionRoute,
    this.data,
  });

  /// Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: _parseNotificationType(data['type']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      imageUrl: data['imageUrl'],
      actionRoute: data['actionRoute'] ?? data['route'],
      data: data['data'] as Map<String, dynamic>?,
    );
  }

  /// Create from Map (for local notifications or FCM)
  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return NotificationModel(
      id: id ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: _parseNotificationType(map['type']),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is DateTime
              ? map['createdAt']
              : DateTime.now()),
      isRead: map['isRead'] ?? false,
      imageUrl: map['imageUrl'],
      actionRoute: map['actionRoute'] ?? map['route'],
      data: map['data'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (actionRoute != null) 'actionRoute': actionRoute,
      if (data != null) 'data': data,
    };
  }

  /// Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? imageUrl,
    String? actionRoute,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      actionRoute: actionRoute ?? this.actionRoute,
      data: data ?? this.data,
    );
  }

  /// Parse notification type from string
  static NotificationType _parseNotificationType(dynamic value) {
    if (value == null) return NotificationType.general;
    if (value is NotificationType) return value;

    final typeStr = value.toString().toLowerCase();
    return NotificationType.values.firstWhere(
      (t) => t.name.toLowerCase() == typeStr,
      orElse: () => NotificationType.general,
    );
  }

  /// Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
