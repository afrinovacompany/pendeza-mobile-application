import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'package:pendeza/app/config/platform_config.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/adaptive_theme.dart';

/// A platform-adaptive elevated/filled button.
/// Uses ElevatedButton on Android and CupertinoButton.filled on iOS.
class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.disabledColor,
    this.textColor,
    this.padding,
    this.borderRadius,
    this.isLoading = false,
    this.isExpanded = false,
  });

  /// Called when the button is pressed
  final VoidCallback? onPressed;

  /// Button content (usually Text widget)
  final Widget child;

  /// Background color of the button
  final Color? color;

  /// Background color when disabled
  final Color? disabledColor;

  /// Text/icon color
  final Color? textColor;

  /// Button padding
  final EdgeInsets? padding;

  /// Border radius
  final BorderRadius? borderRadius;

  /// Show loading indicator instead of child
  final bool isLoading;

  /// Expand to fill available width
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = color ?? colorScheme.primary;
    final fgColor = textColor ?? colorScheme.onPrimary;
    final effectivePadding =
        padding ?? AdaptiveTheme.adaptiveButtonPadding;
    final effectiveRadius =
        borderRadius ?? AdaptiveTheme.adaptiveButtonRadius;

    final buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: PlatformConfig.useCupertino
                ? CupertinoActivityIndicator(color: fgColor)
                : CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  ),
          )
        : child;

    Widget button = PlatformElevatedButton(
      onPressed: isLoading ? null : onPressed,
      padding: effectivePadding,
      color: bgColor,
      child: DefaultTextStyle(
        style: TextStyle(
          color: fgColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        child: buttonChild,
      ),
      material: (_, _) => MaterialElevatedButtonData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor:
              disabledColor ?? bgColor.withAlpha(128),
          padding: effectivePadding,
          elevation: 4,
          shadowColor: bgColor.withAlpha(77),
          shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
        ),
      ),
      cupertino: (_, _) => CupertinoElevatedButtonData(
        color: bgColor,
        disabledColor: disabledColor ?? bgColor.withAlpha(128),
        padding: effectivePadding,
        borderRadius: effectiveRadius,
      ),
    );

    if (isExpanded) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}

/// A platform-adaptive text/flat button.
/// Uses TextButton on Android and CupertinoButton on iOS.
class AdaptiveTextButton extends StatelessWidget {
  const AdaptiveTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.padding,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        color ?? (isDark ? AppColors.primaryLight : AppColors.primary);

    return PlatformTextButton(
      onPressed: onPressed,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DefaultTextStyle(
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        child: child,
      ),
      material: (_, _) => MaterialTextButtonData(
        style: TextButton.styleFrom(
          foregroundColor: textColor,
        ),
      ),
      cupertino: (_, _) => CupertinoTextButtonData(
        color: textColor,
      ),
    );
  }
}

/// A platform-adaptive outlined button.
/// Uses OutlinedButton on Android and bordered CupertinoButton on iOS.
class AdaptiveOutlinedButton extends StatelessWidget {
  const AdaptiveOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.borderColor,
    this.padding,
    this.borderRadius,
    this.isExpanded = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final Color? borderColor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        color ?? (isDark ? AppColors.primaryLight : AppColors.primary);
    final effectiveBorderColor = borderColor ?? textColor;
    final effectivePadding =
        padding ?? AdaptiveTheme.adaptiveButtonPadding;
    final effectiveRadius =
        borderRadius ?? AdaptiveTheme.adaptiveButtonRadius;

    Widget button;

    if (PlatformConfig.useCupertino) {
      button = CupertinoButton(
        onPressed: onPressed,
        padding: effectivePadding,
        color: Colors.transparent,
        child: DefaultTextStyle(
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          child: child,
        ),
      );
      button = Container(
        decoration: BoxDecoration(
          border: Border.all(color: effectiveBorderColor, width: 1.5),
          borderRadius: effectiveRadius,
        ),
        child: ClipRRect(
          borderRadius: effectiveRadius,
          child: button,
        ),
      );
    } else {
      button = OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          padding: effectivePadding,
          side: BorderSide(color: effectiveBorderColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          child: child,
        ),
      );
    }

    if (isExpanded) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}

/// A platform-adaptive icon button.
class AdaptiveIconButton extends StatelessWidget {
  const AdaptiveIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.size,
    this.tooltip,
    this.padding,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final Color? color;
  final double? size;
  final String? tooltip;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ??
        (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);
    final iconSize = size ?? AdaptiveTheme.adaptiveIconSize;

    return PlatformIconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: iconColor, size: iconSize),
      padding: padding ?? const EdgeInsets.all(8),
      material: (_, _) => MaterialIconButtonData(
        tooltip: tooltip,
        splashRadius: 24,
      ),
      cupertino: (_, _) => CupertinoIconButtonData(
        padding: padding ?? const EdgeInsets.all(8),
      ),
    );
  }
}

/// A gradient button with platform-adaptive styling
class AdaptiveGradientButton extends StatelessWidget {
  const AdaptiveGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.padding,
    this.borderRadius,
    this.isLoading = false,
    this.isExpanded = false,
    this.elevation = 4.0,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Gradient? gradient;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final bool isExpanded;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveGradient = gradient ??
        (isDark ? AppColors.darkPrimaryGradient : AppColors.primaryGradient);
    final effectivePadding =
        padding ?? AdaptiveTheme.adaptiveButtonPadding;
    final effectiveRadius =
        borderRadius ?? AdaptiveTheme.adaptiveButtonRadius;

    final buttonChild = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            child: child,
          );

    Widget button = Material(
      color: Colors.transparent,
      elevation: PlatformConfig.useCupertino ? 0 : elevation,
      shadowColor: AppColors.primary.withAlpha(77),
      borderRadius: effectiveRadius,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: effectiveRadius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: effectiveGradient,
            borderRadius: effectiveRadius,
          ),
          child: Container(
            padding: effectivePadding,
            alignment: Alignment.center,
            child: buttonChild,
          ),
        ),
      ),
    );

    if (isExpanded) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}

/// A floating action button that adapts to platform
class AdaptiveFloatingActionButton extends StatelessWidget {
  const AdaptiveFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.heroTag,
    this.mini = false,
    this.extended = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Object? heroTag;
  final bool mini;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.primary;
    final fgColor = foregroundColor ?? colorScheme.onPrimary;

    // On iOS, we still use a Material FAB but with subtle styling
    if (extended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon, color: fgColor),
        label: Text(
          label!,
          style: TextStyle(color: fgColor, fontWeight: FontWeight.w600),
        ),
        backgroundColor: bgColor,
        elevation: PlatformConfig.useCupertino ? 2 : 6,
        heroTag: heroTag,
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: PlatformConfig.useCupertino ? 2 : 6,
      mini: mini,
      heroTag: heroTag,
      child: Icon(icon),
    );
  }
}
