import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/config/app_router.dart';

class QuickActionsBar extends StatelessWidget {
  final Function(String action)? onActionTap;

  const QuickActionsBar({
    super.key,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 105,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildActionItem(
            context,
            'client.dashboard.quick_actions.offers'.tr(),
            CupertinoIcons.tag_fill,
            colors.error,
            onTap: () {
              onActionTap?.call('offers');
              // Navigate to discovery without extra filter
              // Discovery screen will handle "offers" logic internally if needed
              context.go(AppRoutes.clientDiscover);
            },
          ),
          const SizedBox(width: 12),
          _buildActionItem(
            context,
            'client.dashboard.quick_actions.near_me'.tr(),
            CupertinoIcons.location_solid,
            colors.primary,
            onTap: () {
              onActionTap?.call('near_me');
              // Navigate to discovery without extra filter
              // Discovery screen will handle "near_me" logic internally if needed
              context.go(AppRoutes.clientDiscover);
            },
          ),
          const SizedBox(width: 12),
          _buildActionItem(
            context,
            'client.dashboard.quick_actions.trending'.tr(),
            CupertinoIcons.flame_fill,
            colors.tertiary,
            onTap: () {
              onActionTap?.call('trending');
              // Navigate to discovery without extra filter
              // Discovery screen will handle "trending" logic internally if needed
              context.go(AppRoutes.clientDiscover);
            },
          ),
          const SizedBox(width: 12),
          _buildActionItem(
            context,
            'client.dashboard.quick_actions.saved'.tr(),
            CupertinoIcons.heart_fill,
            colors.secondary,
            onTap: () {
              onActionTap?.call('favorites');
              context.push('/client/favorites');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
      BuildContext context,
      String label,
      IconData icon,
      Color color, {
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    // Responsive width based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth / 5).clamp(72.0, 90.0);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32, // Fixed height to prevent overflow
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}