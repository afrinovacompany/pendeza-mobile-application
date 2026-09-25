import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/theme/app_colors.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../../shared/widgets/client_ui.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../widgets/notification_list_item.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: ClientTheme.background(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                final loaded = state is NotificationLoaded ? state : null;
                final unread = loaded?.notifications
                        .where((n) => !n.isRead)
                        .length ??
                    0;

                return ClientPageHeader(
                  title: 'notifications.title'.tr(),
                  subtitle: unread > 0
                      ? 'notifications.unread_count'.tr(args: ['$unread'])
                      : null,
                  actions: [
                    if (loaded != null && loaded.hasNotifications)
                      _MenuButton(hasUnread: loaded.hasUnread),
                  ],
                );
              },
            ),
            Expanded(
              child: BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  if (state is NotificationLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is NotificationError) {
                    return _buildErrorState(context, state.message);
                  }

                  if (state is NotificationLoaded) {
                    if (!state.hasNotifications) {
                      return _buildEmptyState(context);
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<NotificationBloc>()
                            .add(const RefreshNotifications());
                      },
                      color: theme.colorScheme.primary,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          ClientTheme.gutter,
                          18,
                          ClientTheme.gutter,
                          32,
                        ),
                        itemCount: state.notifications.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notification = state.notifications[index];
                          return NotificationListItem(
                            notification: notification,
                            onTap: () =>
                                _handleNotificationTap(context, notification),
                            onDismiss: () =>
                                _handleDismiss(context, notification),
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ClientEmptyState(
      icon: CupertinoIcons.bell_slash_fill,
      title: 'notifications.empty_title'.tr(),
      message: 'notifications.empty_message'.tr(),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return ClientEmptyState(
      icon: CupertinoIcons.exclamationmark_triangle_fill,
      title: 'notifications.error_title'.tr(),
      message: message,
      actionLabel: 'common.retry'.tr(),
      onAction: () {
        context.read<NotificationBloc>().add(const LoadNotifications());
      },
      color: AppColors.error,
    );
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) {
    // Mark as read
    if (!notification.isRead) {
      context
          .read<NotificationBloc>()
          .add(MarkNotificationAsRead(notification.id));
    }

    // Navigate if there's an action route
    if (notification.actionRoute != null &&
        notification.actionRoute!.isNotEmpty) {
      context.push(notification.actionRoute!);
    }
  }

  void _handleDismiss(BuildContext context, NotificationModel notification) {
    final bloc = context.read<NotificationBloc>();
    bloc.add(DeleteNotification(notification.id));

    // The snackbar stays as long as the bloc keeps the delete undoable.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('notifications.deleted'.tr()),
          duration: bloc.undoWindow,
          // A snackbar with an action stays up by default; this one must go
          // when the undo window closes.
          persist: false,
          action: SnackBarAction(
            label: 'common.undo'.tr(),
            onPressed: () =>
                bloc.add(UndoDeleteNotification(notification.id)),
          ),
        ),
      );
  }
}

class _MenuButton extends StatelessWidget {
  final bool hasUnread;

  const _MenuButton({required this.hasUnread});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: const Icon(CupertinoIcons.ellipsis, color: Colors.white, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.20),
        fixedSize: const Size(42, 42),
        shape: CircleBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) => _handleMenuAction(context, value),
      itemBuilder: (context) => [
        if (hasUnread)
          PopupMenuItem(
            value: 'mark_all_read',
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.checkmark_circle,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text('notifications.mark_all_read'.tr()),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete_all',
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.trash,
                size: 20,
                color: AppColors.error,
              ),
              const SizedBox(width: 12),
              Text(
                'notifications.delete_all'.tr(),
                style: const TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'mark_all_read':
        context
            .read<NotificationBloc>()
            .add(const MarkAllNotificationsAsRead());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('notifications.all_marked_read'.tr()),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'delete_all':
        _showDeleteAllConfirmation(context);
        break;
    }
  }

  void _showDeleteAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('notifications.delete_all_title'.tr()),
        content: Text('notifications.delete_all_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<NotificationBloc>()
                  .add(const DeleteAllNotifications());
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }
}
