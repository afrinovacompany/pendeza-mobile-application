import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_notifications/domain/repositories/notification_repository.dart';
import 'package:pendeza/shared/models/notification_model.dart';

import 'notification_event.dart';
import 'notification_state.dart';

/// A swiped-away notification waiting out its undo window.
class _PendingDelete {
  final NotificationModel notification;
  final Timer timer;

  _PendingDelete(this.notification, this.timer);
}

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  /// How long a deleted notification can still be brought back.
  static const Duration defaultUndoWindow = Duration(seconds: 4);

  final NotificationRepository _repository;
  final AuthBloc _authBloc;
  final Duration undoWindow;

  /// Deleted from the list but not yet from Firestore, keyed by notification id.
  final Map<String, _PendingDelete> _pendingDeletes = {};

  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  NotificationBloc({
    required NotificationRepository repository,
    required AuthBloc authBloc,
    this.undoWindow = defaultUndoWindow,
  })  : _repository = repository,
        _authBloc = authBloc,
        super(const NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<UndoDeleteNotification>(_onUndoDeleteNotification);
    on<CommitNotificationDelete>(_onCommitNotificationDelete);
    on<DeleteAllNotifications>(_onDeleteAllNotifications);
    on<UpdateUnreadCount>(_onUpdateUnreadCount);

    // Listen to auth state changes
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is Authenticated) {
        add(const LoadNotifications());
      } else {
        _cancelSubscriptions();
        _dropPendingDeletes();
        // ignore: invalid_use_of_visible_for_testing_member
        emit(const NotificationInitial());
      }
    });

    // Load notifications if already authenticated
    if (_authBloc.state is Authenticated) {
      add(const LoadNotifications());
    }
  }

  String? get _currentUserId {
    final authState = _authBloc.state;
    if (authState is Authenticated) {
      return authState.user.uid;
    }
    return null;
  }

  /// Get user role from auth state.
  /// Returns null if role can't be determined — broadcasts will show for all users.
  /// TODO: Update this to match your Authenticated state structure if needed.
  /// For example: return authState.userProfile?.role;
  /// or: return authState.user?.role;
  String? get _currentUserRole {
    // ignore: unused_local_variable
    final authState = _authBloc.state;
    // If your Authenticated state has userProfile.role, uncomment:
    // if (authState is Authenticated) return authState.userProfile?.role;
    return null; // Shows all broadcasts regardless of role
  }

  Future<void> _onLoadNotifications(
      LoadNotifications event,
      Emitter<NotificationState> emit,
      ) async {
    final userId = _currentUserId;
    if (userId == null) {
      emit(const NotificationError('User not authenticated'));
      return;
    }

    emit(const NotificationLoading());

    try {
      await _cancelSubscriptions();

      // Get merged notifications (personal + broadcasts)
      final notifications = await _repository.getNotifications(
        userId,
        userRole: _currentUserRole,
      );
      final unreadCount = await _repository.getUnreadCount(
        userId,
        userRole: _currentUserRole,
      );

      emit(NotificationLoaded(
        notifications: _withoutPending(notifications),
        unreadCount: _minusPendingUnread(unreadCount),
      ));

      // Setup streams for real-time personal notification updates
      _setupStreams(userId);
    } catch (e, stackTrace) {
      log.e('Error loading notifications', error: e, stackTrace: stackTrace);
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onRefreshNotifications(
      RefreshNotifications event,
      Emitter<NotificationState> emit,
      ) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      // Refresh merged notifications
      final notifications = await _repository.getNotifications(
        userId,
        userRole: _currentUserRole,
      );
      final unreadCount = await _repository.getUnreadCount(
        userId,
        userRole: _currentUserRole,
      );

      emit(NotificationLoaded(
        notifications: _withoutPending(notifications),
        unreadCount: _minusPendingUnread(unreadCount),
      ));
    } catch (e, stackTrace) {
      log.e('Error refreshing notifications', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _onMarkAsRead(
      MarkNotificationAsRead event,
      Emitter<NotificationState> emit,
      ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      // Find the notification
      final notification = currentState.notifications.firstWhere(
            (n) => n.id == event.notificationId,
        orElse: () => throw Exception('Notification not found'),
      );

      // Handle broadcast vs personal
      if (notification.isBroadcast) {
        await _repository.markBroadcastAsRead(
          notification.firestoreId,
          userId,
        );
      } else {
        await _repository.markAsRead(event.notificationId);
      }

      // Update local state
      final updatedNotifications = currentState.notifications.map((n) {
        if (n.id == event.notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      emit(currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount:
        (currentState.unreadCount - 1).clamp(0, double.maxFinite.toInt()),
      ));
    } catch (e, stackTrace) {
      log.e('Error marking notification as read',
          error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _onMarkAllAsRead(
      MarkAllNotificationsAsRead event,
      Emitter<NotificationState> emit,
      ) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    try {
      await _repository.markAllAsRead(userId);

      // Update local state — mark all as read
      final updatedNotifications = currentState.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();

      emit(currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      ));
    } catch (e, stackTrace) {
      log.e('Error marking all notifications as read',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Removes the notification from the list right away and starts the undo
  /// window; the real delete happens in [_onCommitNotificationDelete].
  void _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;
    if (_pendingDeletes.containsKey(event.notificationId)) return;

    final matches =
        currentState.notifications.where((n) => n.id == event.notificationId);
    if (matches.isEmpty) return;
    final notification = matches.first;

    _pendingDeletes[event.notificationId] = _PendingDelete(
      notification,
      Timer(undoWindow, () {
        if (!isClosed) add(CommitNotificationDelete(event.notificationId));
      }),
    );

    emit(currentState.copyWith(
      notifications: currentState.notifications
          .where((n) => n.id != event.notificationId)
          .toList(),
      unreadCount: notification.isRead
          ? currentState.unreadCount
          : (currentState.unreadCount - 1).clamp(0, double.maxFinite.toInt()),
    ));
  }

  void _onUndoDeleteNotification(
    UndoDeleteNotification event,
    Emitter<NotificationState> emit,
  ) {
    final pending = _pendingDeletes.remove(event.notificationId);
    if (pending == null) return; // window already closed
    pending.timer.cancel();

    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    emit(currentState.copyWith(
      notifications: _insertSorted(
        currentState.notifications,
        pending.notification,
      ),
      unreadCount:
          currentState.unreadCount + (pending.notification.isRead ? 0 : 1),
    ));
  }

  Future<void> _onCommitNotificationDelete(
    CommitNotificationDelete event,
    Emitter<NotificationState> emit,
  ) async {
    final pending = _pendingDeletes[event.notificationId];
    if (pending == null) return;

    try {
      // Broadcasts can't be deleted - they were only hidden from the list.
      if (!pending.notification.isBroadcast) {
        await _repository.deleteNotification(event.notificationId);
      }
      _pendingDeletes.remove(event.notificationId);
    } catch (e, stackTrace) {
      log.e('Error deleting notification', error: e, stackTrace: stackTrace);
      // The delete failed, so the notification still exists: show it again.
      _pendingDeletes.remove(event.notificationId);
      final currentState = state;
      if (currentState is NotificationLoaded) {
        emit(currentState.copyWith(
          notifications: _insertSorted(
            currentState.notifications,
            pending.notification,
          ),
          unreadCount:
              currentState.unreadCount + (pending.notification.isRead ? 0 : 1),
        ));
      }
    }
  }

  /// [notifications] minus the ones waiting out their undo window (a refresh
  /// or stream update would otherwise bring them straight back).
  List<NotificationModel> _withoutPending(
      List<NotificationModel> notifications) {
    if (_pendingDeletes.isEmpty) return notifications;
    return notifications
        .where((n) => !_pendingDeletes.containsKey(n.id))
        .toList();
  }

  int _minusPendingUnread(int count) {
    final pendingUnread = _pendingDeletes.values
        .where((p) => !p.notification.isRead && !p.notification.isBroadcast)
        .length;
    return (count - pendingUnread).clamp(0, double.maxFinite.toInt());
  }

  List<NotificationModel> _insertSorted(
    List<NotificationModel> notifications,
    NotificationModel notification,
  ) {
    return [...notifications, notification]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _dropPendingDeletes() {
    for (final pending in _pendingDeletes.values) {
      pending.timer.cancel();
    }
    _pendingDeletes.clear();
  }

  Future<void> _onDeleteAllNotifications(
      DeleteAllNotifications event,
      Emitter<NotificationState> emit,
      ) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      // Only delete personal notifications
      await _repository.deleteAllNotifications(userId);
      _dropPendingDeletes();

      // Keep broadcasts in the list but mark as read
      final currentState = state;
      if (currentState is NotificationLoaded) {
        final remainingBroadcasts = currentState.notifications
            .where((n) => n.isBroadcast)
            .map((n) => n.copyWith(isRead: true))
            .toList();

        emit(NotificationLoaded(
          notifications: remainingBroadcasts,
          unreadCount: 0,
        ));
      } else {
        emit(const NotificationLoaded(
          notifications: [],
          unreadCount: 0,
        ));
      }
    } catch (e, stackTrace) {
      log.e('Error deleting all notifications',
          error: e, stackTrace: stackTrace);
    }
  }

  void _onUpdateUnreadCount(
      UpdateUnreadCount event,
      Emitter<NotificationState> emit,
      ) {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      emit(currentState.copyWith(
        unreadCount: _minusPendingUnread(event.count),
      ));
    }
  }

  void _setupStreams(String userId) {
    // Stream personal notifications for real-time updates
    // When personal notifications change, refresh the full merged list
    _notificationsSubscription = _repository
        .streamNotifications(userId)
        .listen((personalNotifications) {
      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;

        // Keep existing broadcasts, replace personal notifications
        final broadcasts =
        currentState.notifications.where((n) => n.isBroadcast).toList();

        final allNotifications = [
          ..._withoutPending(personalNotifications),
          ...broadcasts,
        ];
        allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // ignore: invalid_use_of_visible_for_testing_member
        emit(currentState.copyWith(notifications: allNotifications));
      }
    });

    // Stream personal unread count
    _unreadCountSubscription =
        _repository.streamUnreadCount(userId).listen((count) {
          add(UpdateUnreadCount(count));
        });
  }

  Future<void> _cancelSubscriptions() async {
    await _notificationsSubscription?.cancel();
    await _unreadCountSubscription?.cancel();
    _notificationsSubscription = null;
    _unreadCountSubscription = null;
  }

  @override
  Future<void> close() async {
    // Finish the deletes the user already confirmed by not undoing them.
    for (final pending in _pendingDeletes.values) {
      pending.timer.cancel();
      if (!pending.notification.isBroadcast) {
        unawaited(_repository
            .deleteNotification(pending.notification.id)
            .catchError((Object e) => log.e('Error deleting notification: $e')));
      }
    }
    _pendingDeletes.clear();
    await _cancelSubscriptions();
    await _authSubscription?.cancel();
    return super.close();
  }
}