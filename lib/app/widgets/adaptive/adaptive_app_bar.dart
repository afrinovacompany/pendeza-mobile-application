import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'package:pendeza/app/config/platform_config.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';

/// A platform-adaptive app bar that uses Material AppBar on Android
/// and CupertinoNavigationBar on iOS.
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdaptiveAppBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
    this.titleWidget,
    this.bottom,
    this.largeTitle = false,
  });

  /// Title text for the app bar
  final String title;

  /// Custom title widget (overrides [title] text)
  final Widget? titleWidget;

  /// Leading widget (usually back button or menu)
  final Widget? leading;

  /// Single trailing widget (for simple cases)
  final Widget? trailing;

  /// Multiple action widgets (Material style, use for multiple actions)
  final List<Widget>? actions;

  /// Whether to automatically add back button
  final bool automaticallyImplyLeading;

  /// Background color of the app bar
  final Color? backgroundColor;

  /// Foreground/text color
  final Color? foregroundColor;

  /// Elevation (Material only)
  final double? elevation;

  /// Whether to center the title
  final bool centerTitle;

  /// Tab bar or other widget below the app bar (Material only)
  final PreferredSizeWidget? bottom;

  /// Use large title style (iOS only)
  final bool largeTitle;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.primary);
    final fgColor = foregroundColor ??
        (isDark ? AppColors.darkTextPrimary : Colors.white);

    // Combine trailing and actions
    final effectiveActions = <Widget>[
      if (trailing != null) trailing!,
      if (actions != null) ...actions!,
    ];

    return PlatformAppBar(
      title: titleWidget ?? Text(title),
      leading: leading,
      trailingActions: effectiveActions.isNotEmpty ? effectiveActions : null,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: bgColor,
      material: (_, _) => MaterialAppBarData(
        elevation: elevation ?? 1,
        centerTitle: centerTitle,
        foregroundColor: fgColor,
        titleTextStyle: TextStyle(
          color: fgColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: fgColor),
        actionsIconTheme: IconThemeData(color: fgColor),
        bottom: bottom,
      ),
      cupertino: (_, _) => CupertinoNavigationBarData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
      ),
    );
  }
}

/// A sliver-based adaptive app bar for use in CustomScrollView
class AdaptiveSliverAppBar extends StatelessWidget {
  const AdaptiveSliverAppBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.expandedHeight,
    this.collapsedHeight,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.stretch = false,
    this.flexibleSpace,
    this.largeTitle = false,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? expandedHeight;
  final double? collapsedHeight;
  final bool pinned;
  final bool floating;
  final bool snap;
  final bool stretch;
  final Widget? flexibleSpace;
  final bool largeTitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.primary);
    final fgColor = foregroundColor ??
        (isDark ? AppColors.darkTextPrimary : Colors.white);

    final effectiveActions = <Widget>[
      if (trailing != null) trailing!,
      if (actions != null) ...actions!,
    ];

    if (PlatformConfig.useCupertino) {
      return CupertinoSliverNavigationBar(
        largeTitle: Text(
          title,
          style: TextStyle(color: fgColor),
        ),
        leading: leading,
        trailing: effectiveActions.isNotEmpty
            ? Row(mainAxisSize: MainAxisSize.min, children: effectiveActions)
            : null,
        automaticallyImplyLeading: automaticallyImplyLeading,
        backgroundColor: bgColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
        ),
        stretch: stretch,
      );
    }

    return SliverAppBar(
      title: Text(title),
      leading: leading,
      actions: effectiveActions.isNotEmpty ? effectiveActions : null,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      pinned: pinned,
      floating: floating,
      snap: snap,
      stretch: stretch,
      flexibleSpace: flexibleSpace,
      elevation: 1,
      centerTitle: true,
    );
  }
}

/// Adaptive back button that respects platform conventions
class AdaptiveBackButton extends StatelessWidget {
  const AdaptiveBackButton({
    super.key,
    this.onPressed,
    this.color,
  });

  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        color ?? (isDark ? AppColors.darkTextPrimary : Colors.white);

    return PlatformIconButton(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: Icon(
        PlatformConfig.useCupertino
            ? CupertinoIcons.back
            : Icons.arrow_back,
        color: iconColor,
      ),
      material: (_, _) => MaterialIconButtonData(
        tooltip: 'Back',
      ),
      cupertino: (_, _) => CupertinoIconButtonData(
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// Adaptive close button for modals/dialogs
class AdaptiveCloseButton extends StatelessWidget {
  const AdaptiveCloseButton({
    super.key,
    this.onPressed,
    this.color,
  });

  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        color ?? (isDark ? AppColors.darkTextPrimary : Colors.white);

    return PlatformIconButton(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: Icon(
        PlatformConfig.useCupertino ? CupertinoIcons.xmark : Icons.close,
        color: iconColor,
      ),
      material: (_, _) => MaterialIconButtonData(
        tooltip: 'Close',
      ),
      cupertino: (_, _) => CupertinoIconButtonData(
        padding: EdgeInsets.zero,
      ),
    );
  }
}
