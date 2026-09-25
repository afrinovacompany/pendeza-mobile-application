import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/config/theme/app_colors.dart';
import '../../../../app/config/theme/app_text_styles.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../../shared/widgets/client_ui.dart';

/// Notification card with:
/// - Type icon (or image thumbnail)
/// - Unread accent
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
    final isDark = ClientTheme.isDark(context);
    final notification = widget.notification;
    final unread = !notification.isRead;
    final tone = _getColorForType(notification.type, Theme.of(context));

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(CupertinoIcons.trash, color: Colors.white),
      ),
      child: ClientCard(
        radius: 22,
        padding: const EdgeInsets.all(14),
        color: unread
            ? ClientTheme.tinted(context, AppColors.primary,
                light: 0.05, dark: 0.14)
            : null,
        borderColor: unread
            ? AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.25)
            : null,
        onTap: () {
          // Toggle expansion if body is long
          if (_isBodyLong(notification.body)) {
            setState(() => _isExpanded = !_isExpanded);
          }
          widget.onTap?.call();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeadingWidget(tone),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: ClientTheme.body(context).copyWith(
                                fontWeight:
                                    unread ? FontWeight.w700 : FontWeight.w600,
                                color: ClientTheme.textPrimary(context),
                              ),
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.topCenter,
                        curve: Curves.easeInOut,
                        child: Text(
                          notification.body,
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: ClientTheme.caption(context).copyWith(
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ),
                      if (_isBodyLong(notification.body) && !_isExpanded)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'notifications.read_more'.tr(),
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Theme.of(context).colorScheme.primary
                                  : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.clock,
                            size: 12,
                            color: ClientTheme.textSecondary(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.timeAgo,
                            style: ClientTheme.caption(context)
                                .copyWith(fontSize: 11.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Chevron for actionable notifications (without CTA button)
                if (notification.actionRoute != null &&
                    notification.actionLabel == null) ...[
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Icon(
                      CupertinoIcons.chevron_right,
                      size: 15,
                      color: ClientTheme.textSecondary(context),
                    ),
                  ),
                ],
              ],
            ),

            // Image (if present)
            if (notification.imageUrl != null &&
                notification.imageUrl!.isNotEmpty)
              _buildNotificationImage(notification.imageUrl!),

            // Call-to-Action Button (if present)
            if (notification.actionRoute != null &&
                notification.actionLabel != null)
              _buildActionButton(),
          ],
        ),
      ),
    );
  }

  /// Check if body text is long enough to need expansion
  bool _isBodyLong(String text) {
    return text.length > 100 || text.contains('\n');
  }

  /// Build leading icon or image thumbnail
  Widget _buildLeadingWidget(Color tone) {
    final notification = widget.notification;
    final icon = ClientIconTile(
      icon: _getIconForType(notification.type),
      color: tone,
      size: 46,
    );

    // If there's an image, show small thumbnail
    if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty) {
      return SizedBox(
        width: 46,
        height: 46,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: CachedNetworkImage(
            imageUrl: notification.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => icon,
            errorWidget: (context, url, error) => icon,
          ),
        ),
      );
    }

    return icon;
  }

  /// Build notification image (large, below content)
  Widget _buildNotificationImage(String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 160,
            color: ClientTheme.inset(context),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 100,
            color: ClientTheme.inset(context),
            child: Center(
              child: Icon(
                CupertinoIcons.photo,
                size: 32,
                color: ClientTheme.textSecondary(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build Call-to-Action button
  Widget _buildActionButton() {
    final notification = widget.notification;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClientPrimaryButton(
        text: notification.actionLabel!,
        icon: CupertinoIcons.arrow_right,
        height: 48,
        onPressed: widget.onActionTap ?? widget.onTap,
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return CupertinoIcons.calendar;
      case NotificationType.promotion:
        return CupertinoIcons.tag_fill;
      case NotificationType.system:
        return CupertinoIcons.gear_solid;
      case NotificationType.payment:
        return CupertinoIcons.creditcard_fill;
      case NotificationType.review:
        return CupertinoIcons.star_fill;
      case NotificationType.general:
        return CupertinoIcons.bell_fill;
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
        return const Color(0xFFF5A623);
      case NotificationType.general:
        return theme.colorScheme.secondary;
    }
  }
}
