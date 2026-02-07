import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/config/theme/app_colors.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/models/notification_model.dart';

/// Enhanced notification list item with:
/// - Image support
/// - Expandable body text (tap to expand/collapse)
/// - Call-to-Action button
/// - Swipe to delete
class NotificationListItem extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onActionTap;

  const NotificationListItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
    this.onActionTap,
  });

  @override
  State<NotificationListItem> createState() => _NotificationListItemState();
}

class _NotificationListItemState extends State<NotificationListItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notification = widget.notification;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(
          CupertinoIcons.trash,
          color: Colors.white,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Toggle expansion if body is long
          if (_isBodyLong(notification.body)) {
            setState(() => _isExpanded = !_isExpanded);
          }
          widget.onTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.padL,
            vertical: AppConstants.padM,
          ),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.transparent
                : (isDark
                ? theme.colorScheme.primary.withOpacity(0.08)
                : theme.colorScheme.primary.withOpacity(0.05)),
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon or Image
                  _buildLeadingWidget(theme, isDark),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with unread indicator
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification.isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Body - Expandable
                        AnimatedCrossFade(
                          firstChild: Text(
                            notification.body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondChild: Text(
                            notification.body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          crossFadeState: _isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),

                        // "Read more" indicator
                        if (_isBodyLong(notification.body) && !_isExpanded)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Tap to read more...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        const SizedBox(height: 6),

                        // Time ago
                        Text(
                          notification.timeAgo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chevron for actionable notifications (without CTA button)
                  if (notification.actionRoute != null &&
                      notification.actionLabel == null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textSecondary.withOpacity(0.5),
                    ),
                  ],
                ],
              ),

              // Image (if present)
              if (notification.imageUrl != null &&
                  notification.imageUrl!.isNotEmpty)
                _buildNotificationImage(notification.imageUrl!, theme),

              // Call-to-Action Button (if present)
              if (notification.actionRoute != null &&
                  notification.actionLabel != null)
                _buildActionButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  /// Check if body text is long enough to need expansion
  bool _isBodyLong(String text) {
    return text.length > 100 || text.contains('\n');
  }

  /// Build leading icon or image thumbnail
  Widget _buildLeadingWidget(ThemeData theme, bool isDark) {
    final notification = widget.notification;

    // If there's an image, show small thumbnail
    if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.dividerColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: notification.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Icon(
              _getIconForType(notification.type),
              size: 22,
              color: _getColorForType(notification.type, theme),
            ),
            errorWidget: (context, url, error) => Icon(
              _getIconForType(notification.type),
              size: 22,
              color: _getColorForType(notification.type, theme),
            ),
          ),
        ),
      );
    }

    // Default icon
    final iconData = _getIconForType(notification.type);
    final iconColor = _getColorForType(notification.type, theme);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        size: 22,
        color: iconColor,
      ),
    );
  }

  /// Build notification image (large, below content)
  Widget _buildNotificationImage(String imageUrl, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.padM),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 160,
            color: theme.dividerColor,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 100,
            color: theme.dividerColor,
            child: const Center(
              child: Icon(CupertinoIcons.photo, size: 32),
            ),
          ),
        ),
      ),
    );
  }

  /// Build Call-to-Action button
  Widget _buildActionButton(ThemeData theme) {
    final notification = widget.notification;
    final buttonColor = _getColorForType(notification.type, theme);

    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.padM),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.onActionTap ?? widget.onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                notification.actionLabel!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(CupertinoIcons.arrow_right, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return CupertinoIcons.calendar;
      case NotificationType.promotion:
        return CupertinoIcons.tag;
      case NotificationType.system:
        return CupertinoIcons.gear;
      case NotificationType.payment:
        return CupertinoIcons.creditcard;
      case NotificationType.review:
        return CupertinoIcons.star;
      case NotificationType.general:
        return CupertinoIcons.bell;
    }
  }

  Color _getColorForType(NotificationType type, ThemeData theme) {
    switch (type) {
      case NotificationType.appointment:
        return AppColors.info;
      case NotificationType.promotion:
        return AppColors.warning;
      case NotificationType.system:
        return theme.colorScheme.primary;
      case NotificationType.payment:
        return AppColors.success;
      case NotificationType.review:
        return Colors.amber;
      case NotificationType.general:
        return theme.colorScheme.secondary;
    }
  }
}
