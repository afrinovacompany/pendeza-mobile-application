import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

/// Loading state
class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

/// Loaded state with notifications
class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    this.unreadCount = 0,
  });

  /// Get unread notifications
  List<NotificationModel> get unreadNotifications =>
      notifications.where((n) => !n.isRead).toList();

  /// Get read notifications
  List<NotificationModel> get readNotifications =>
      notifications.where((n) => n.isRead).toList();

  /// Check if there are any notifications
  bool get hasNotifications => notifications.isNotEmpty;

  /// Check if there are unread notifications
  bool get hasUnread => unreadCount > 0;

  @override
  List<Object?> get props => [notifications, unreadCount];

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Error state
class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
