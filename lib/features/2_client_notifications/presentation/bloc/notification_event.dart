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

/// Delete a single notification.
///
/// It disappears from the list straight away but is only removed for good
/// once the undo window ([NotificationBloc.undoWindow]) has passed; until then
/// [UndoDeleteNotification] brings it back.
class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Put back a notification that was just deleted (only works while the undo
/// window is still open).
class UndoDeleteNotification extends NotificationEvent {
  final String notificationId;

  const UndoDeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Internal: the undo window closed, so delete the notification for real.
class CommitNotificationDelete extends NotificationEvent {
  final String notificationId;

  const CommitNotificationDelete(this.notificationId);

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
