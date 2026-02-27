import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_notifications/domain/repositories/notification_repository.dart';
import 'package:pendeza/shared/models/notification_model.dart';

import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  final AuthBloc _authBloc;

  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  NotificationBloc({
    required NotificationRepository repository,
    required AuthBloc authBloc,
  })  : _repository = repository,
        _authBloc = authBloc,
        super(const NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<DeleteAllNotifications>(_onDeleteAllNotifications);
    on<UpdateUnreadCount>(_onUpdateUnreadCount);

    // Listen to auth state changes
    _authSubscription = _authBloc.stream.listen((authState) {
      if (authState is Authenticated) {
        add(const LoadNotifications());
      } else {
        _cancelSubscriptions();
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
        notifications: notifications,
        unreadCount: unreadCount,
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
        notifications: notifications,
        unreadCount: unreadCount,
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

  Future<void> _onDeleteNotification(
      DeleteNotification event,
      Emitter<NotificationState> emit,
      ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    try {
      final notification = currentState.notifications.firstWhere(
            (n) => n.id == event.notificationId,
        orElse: () => throw Exception('Notification not found'),
      );

      // Broadcasts can't be deleted — just remove from local list
      if (!notification.isBroadcast) {
        await _repository.deleteNotification(event.notificationId);
      }

      // Remove from local state
      final updatedNotifications = currentState.notifications
          .where((n) => n.id != event.notificationId)
          .toList();

      emit(currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: notification.isRead
            ? currentState.unreadCount
            : (currentState.unreadCount - 1)
            .clamp(0, double.maxFinite.toInt()),
      ));
    } catch (e, stackTrace) {
      log.e('Error deleting notification', error: e, stackTrace: stackTrace);
    }
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
      emit(currentState.copyWith(unreadCount: event.count));
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
          ...personalNotifications,
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
    await _cancelSubscriptions();
    await _authSubscription?.cancel();
    return super.close();
  }
}