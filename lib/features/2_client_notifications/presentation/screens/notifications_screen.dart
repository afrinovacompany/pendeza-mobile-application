import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/theme/app_colors.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('notifications.title'.tr()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded && state.hasUnread) {
                return PopupMenuButton<String>(
                  icon: Icon(
                    CupertinoIcons.ellipsis_vertical,
                    color: theme.colorScheme.onSurface,
                  ),
                  onSelected: (value) => _handleMenuAction(context, value),
                  itemBuilder: (context) => [
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
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
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
                context.read<NotificationBloc>().add(const RefreshNotifications());
              },
              color: theme.colorScheme.primary,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppConstants.padM),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return NotificationListItem(
                    notification: notification,
                    onTap: () => _handleNotificationTap(context, notification),
                    onDismiss: () => _handleDismiss(context, notification),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      iconData: CupertinoIcons.bell_slash,
      title: 'notifications.empty_title'.tr(),
      message: 'notifications.empty_message'.tr(),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'notifications.error_title'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<NotificationBloc>().add(const LoadNotifications());
              },
              icon: const Icon(CupertinoIcons.refresh),
              label: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) {
    // Mark as read
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(MarkNotificationAsRead(notification.id));
    }

    // Navigate if there's an action route
    if (notification.actionRoute != null && notification.actionRoute!.isNotEmpty) {
      context.push(notification.actionRoute!);
    }
  }

  void _handleDismiss(BuildContext context, NotificationModel notification) {
    context.read<NotificationBloc>().add(DeleteNotification(notification.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('notifications.deleted'.tr()),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'common.undo'.tr(),
          onPressed: () {
            // TODO: Implement undo functionality if needed
          },
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'mark_all_read':
        context.read<NotificationBloc>().add(const MarkAllNotificationsAsRead());
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
              context.read<NotificationBloc>().add(const DeleteAllNotifications());
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }
}
