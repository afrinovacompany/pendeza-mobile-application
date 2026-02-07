import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load notifications for the current user
class LoadNotifications extends NotificationEvent {
  const LoadNotifications();
}

/// Refresh notifications
class RefreshNotifications extends NotificationEvent {
  const RefreshNotifications();
}

/// Mark a single notification as read
class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Mark all notifications as read
class MarkAllNotificationsAsRead extends NotificationEvent {
  const MarkAllNotificationsAsRead();
}

/// Delete a single notification
class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Delete all notifications
class DeleteAllNotifications extends NotificationEvent {
  const DeleteAllNotifications();
}

/// Update unread count (usually from stream)
class UpdateUnreadCount extends NotificationEvent {
  final int count;

  const UpdateUnreadCount(this.count);

  @override
  List<Object?> get props => [count];
}
