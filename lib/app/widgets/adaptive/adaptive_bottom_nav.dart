import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'package:pendeza/app/config/platform_config.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';

/// Represents a navigation item for the adaptive bottom navigation bar.
class AdaptiveNavItem {
  const AdaptiveNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.badge,
  });

  /// The icon to display when inactive
  final IconData icon;

  /// The label text for this item
  final String label;

  /// Optional icon to display when active (defaults to [icon])
  final IconData? activeIcon;

  /// Optional badge count (displays a badge if > 0)
  final int? badge;
}

/// A platform-adaptive bottom navigation bar.
/// Uses BottomNavigationBar on Android and CupertinoTabBar on iOS.
class AdaptiveBottomNav extends StatelessWidget {
  const AdaptiveBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.showLabels = true,
    this.elevation = 8.0,
    this.iconSize = 24.0,
    this.selectedFontSize = 12.0,
    this.unselectedFontSize = 12.0,
    this.type,
  });

  /// List of navigation items
  final List<AdaptiveNavItem> items;

  /// Currently selected index
  final int currentIndex;

  /// Callback when an item is tapped
  final ValueChanged<int> onTap;

  /// Background color of the navigation bar
  final Color? backgroundColor;

  /// Color of the active/selected item
  final Color? activeColor;

  /// Color of inactive items
  final Color? inactiveColor;

  /// Whether to show labels below icons
  final bool showLabels;

  /// Elevation (Material only)
  final double elevation;

  /// Size of the icons
  final double iconSize;

  /// Font size for selected label (Material only)
  final double selectedFontSize;

  /// Font size for unselected label (Material only)
  final double unselectedFontSize;

  /// Navigation bar type (Material only)
  final BottomNavigationBarType? type;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.surface);
    final selectedColor = activeColor ??
        (isDark ? AppColors.primaryLight : AppColors.primary);
    final unselectedColor = inactiveColor ??
        (isDark ? AppColors.darkTextTertiary : AppColors.textSecondary);

    return PlatformNavBar(
      currentIndex: currentIndex,
      itemChanged: onTap,
      backgroundColor: bgColor,
      items: items
          .map((item) => BottomNavigationBarItem(
                icon: _buildNavIcon(
                  item.icon,
                  item.badge,
                  unselectedColor,
                  isDark,
                ),
                activeIcon: _buildNavIcon(
                  item.activeIcon ?? item.icon,
                  item.badge,
                  selectedColor,
                  isDark,
                ),
                label: item.label,
              ))
          .toList(),
      material: (_, __) => MaterialNavBarData(
        elevation: elevation,
        type: type ?? BottomNavigationBarType.fixed,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        showSelectedLabels: showLabels,
        showUnselectedLabels: showLabels,
        selectedFontSize: selectedFontSize,
        unselectedFontSize: unselectedFontSize,
        iconSize: iconSize,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
      ),
      cupertino: (_, __) => CupertinoTabBarData(
        activeColor: selectedColor,
        inactiveColor: unselectedColor,
        iconSize: iconSize,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(
    IconData icon,
    int? badge,
    Color color,
    bool isDark,
  ) {
    final iconWidget = Icon(icon, color: color, size: iconSize);

    if (badge == null || badge <= 0) {
      return iconWidget;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          top: -4,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                badge > 99 ? '99+' : badge.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A more customizable adaptive bottom navigation with support for
/// custom item builders and animations.
class AdaptiveBottomNavBar extends StatelessWidget {
  const AdaptiveBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.height = 60.0,
    this.iconSize = 24.0,
    this.labelSize = 11.0,
    this.showLabels = true,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  final List<AdaptiveNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final double height;
  final double iconSize;
  final double labelSize;
  final bool showLabels;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.surface);
    final selectedColor = activeColor ??
        (isDark ? AppColors.primaryLight : AppColors.primary);
    final unselectedColor = inactiveColor ??
        (isDark ? AppColors.darkTextTertiary : AppColors.textSecondary);

    return Container(
      height: height + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
        ),
        boxShadow: PlatformConfig.useCupertino
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;
            final color = isSelected ? selectedColor : unselectedColor;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: animationDuration,
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAnimatedIcon(
                        item: item,
                        isSelected: isSelected,
                        color: color,
                        isDark: isDark,
                      ),
                      if (showLabels) ...[
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: animationDuration,
                          style: TextStyle(
                            color: color,
                            fontSize: labelSize,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontFamily: 'Poppins',
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon({
    required AdaptiveNavItem item,
    required bool isSelected,
    required Color color,
    required bool isDark,
  }) {
    final icon = isSelected ? (item.activeIcon ?? item.icon) : item.icon;

    Widget iconWidget = AnimatedScale(
      scale: isSelected ? 1.1 : 1.0,
      duration: animationDuration,
      child: Icon(icon, color: color, size: iconSize),
    );

    if (item.badge != null && item.badge! > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            top: -4,
            right: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  item.badge! > 99 ? '99+' : item.badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return iconWidget;
  }
}

/// A floating bottom navigation bar with a modern design.
class AdaptiveFloatingBottomNav extends StatelessWidget {
  const AdaptiveFloatingBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    this.borderRadius = 24.0,
    this.iconSize = 24.0,
    this.showLabels = false,
    this.elevation = 8.0,
  });

  final List<AdaptiveNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final double borderRadius;
  final double iconSize;
  final bool showLabels;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkSurfaceVariant : AppColors.surface);
    final selectedColor = activeColor ??
        (isDark ? AppColors.primaryLight : AppColors.primary);
    final unselectedColor = inactiveColor ??
        (isDark ? AppColors.darkTextTertiary : AppColors.textSecondary);

    return Container(
      margin: margin.copyWith(
        bottom: margin.bottom + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(77)
                : Colors.black.withAlpha(31),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation / 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;
            final color = isSelected ? selectedColor : unselectedColor;

            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 16 : 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedColor.withAlpha(31)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(borderRadius / 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIcon(item, isSelected, color, isDark),
                    if (showLabels && isSelected) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildIcon(
    AdaptiveNavItem item,
    bool isSelected,
    Color color,
    bool isDark,
  ) {
    final icon = isSelected ? (item.activeIcon ?? item.icon) : item.icon;

    Widget iconWidget = Icon(icon, color: color, size: iconSize);

    if (item.badge != null && item.badge! > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.surface,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  item.badge! > 9 ? '9+' : item.badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return iconWidget;
  }
}
