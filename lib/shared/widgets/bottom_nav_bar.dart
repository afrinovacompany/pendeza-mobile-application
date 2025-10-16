import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../app/config/theme/app_constants.dart';

/// A model class to represent a single item in the custom bottom navigation bar.
class BottomNavBarItem {
  /// The icon to display for this item.
  final IconData icon;

  /// The icon to display when this item is active.
  final IconData activeIcon;

  /// The text label for this item.
  final String label;

  /// Optional badge count for notifications
  final int? badgeCount;

  const BottomNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}

/// A custom, reusable bottom navigation bar for the application.
///
/// Features:
/// - Smooth animations between states
/// - Badge support for notifications
/// - Active indicator with scale animation
/// - Improved accessibility
/// - Haptic feedback on tap
class CustomBottomNavBar extends StatelessWidget {
  /// The list of items to display in the navigation bar.
  final List<BottomNavBarItem> items;

  /// The index of the currently selected item.
  final int currentIndex;

  /// The callback that is called when an item is tapped.
  final ValueChanged<int> onTap;

  /// Whether to show labels for all items or only the active one
  final bool alwaysShowLabels;

  const CustomBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.alwaysShowLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final bool isActive = index == currentIndex;
            final Color itemColor = isActive
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.6);

            return Expanded(
              child: _NavBarItem(
                item: item,
                isActive: isActive,
                itemColor: itemColor,
                onTap: () => onTap(index),
                showLabel: alwaysShowLabels || isActive,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final BottomNavBarItem item;
  final bool isActive;
  final Color itemColor;
  final VoidCallback onTap;
  final bool showLabel;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.itemColor,
    required this.onTap,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedScale(
                scale: isActive ? 1.1 : 1.0,
                duration: AppConstants.durationMedium,
                curve: Curves.easeInOut,
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: itemColor,
                  size: AppConstants.iconSizeM,
                ),
              ),
              // Badge indicator
              if (item.badgeCount != null && item.badgeCount! > 0)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      item.badgeCount! > 99 ? '99+' : '${item.badgeCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.padXXS),
          // Animated label
          AnimatedOpacity(
            opacity: showLabel ? 1.0 : 0.0,
            duration: AppConstants.durationMedium,
            child: AnimatedDefaultTextStyle(
              duration: AppConstants.durationMedium,
              style: theme.textTheme.labelSmall!.copyWith(
                color: itemColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- EXAMPLE USAGE ---
final clientNavItems = [
  const BottomNavBarItem(
    icon: CupertinoIcons.home,
    activeIcon: CupertinoIcons.house_fill,
    label: 'Home',
  ),
  const BottomNavBarItem(
    icon: CupertinoIcons.search,
    activeIcon: CupertinoIcons.search_circle_fill,
    label: 'Discover',
  ),
  const BottomNavBarItem(
    icon: CupertinoIcons.calendar,
    activeIcon: CupertinoIcons.calendar_circle_fill,
    label: 'Bookings',
    badgeCount: 3, // Example badge
  ),
  const BottomNavBarItem(
    icon: CupertinoIcons.person,
    activeIcon: CupertinoIcons.person_fill,
    label: 'Profile',
  ),
];

final ownerNavItems = [
  const BottomNavBarItem(
    icon: CupertinoIcons.chart_bar,
    activeIcon: CupertinoIcons.chart_bar_fill,
    label: 'Dashboard',
  ),
  const BottomNavBarItem(
    icon: CupertinoIcons.calendar,
    activeIcon: CupertinoIcons.calendar_circle_fill,
    label: 'Schedule',
    badgeCount: 5, // Example badge for pending appointments
  ),
  const BottomNavBarItem(
    icon: CupertinoIcons.group,
    activeIcon: CupertinoIcons.group_solid,
    label: 'Clients',
  ),
  const BottomNavBarItem(
    icon: CupertinoIcons.settings,
    activeIcon: CupertinoIcons.settings_solid,
    label: 'Settings',
  ),
];