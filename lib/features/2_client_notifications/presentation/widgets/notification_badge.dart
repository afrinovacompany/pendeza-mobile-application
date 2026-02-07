import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/notification_bloc.dart';
import '../bloc/notification_state.dart';

/// A notification bell icon with badge showing unread count
class NotificationBadge extends StatelessWidget {
  final VoidCallback onTap;
  final double iconSize;
  final Color? iconColor;

  const NotificationBadge({
    super.key,
    required this.onTap,
    this.iconSize = 24,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        int unreadCount = 0;
        if (state is NotificationLoaded) {
          unreadCount = state.unreadCount;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: onTap,
                icon: Icon(
                  CupertinoIcons.bell,
                  color: iconColor ?? theme.colorScheme.onSurface,
                  size: iconSize,
                ),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: _buildBadge(unreadCount, theme),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBadge(int count, ThemeData theme) {
    final displayCount = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.orange],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.scaffoldBackgroundColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayCount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// A simpler notification badge without the container styling
class SimpleNotificationBadge extends StatelessWidget {
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? badgeColor;

  const SimpleNotificationBadge({
    super.key,
    required this.onTap,
    this.iconColor,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        int unreadCount = 0;
        if (state is NotificationLoaded) {
          unreadCount = state.unreadCount;
        }

        return IconButton(
          onPressed: onTap,
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: badgeColor ?? Colors.red,
            child: Icon(
              CupertinoIcons.bell,
              color: iconColor ?? theme.colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }
}
