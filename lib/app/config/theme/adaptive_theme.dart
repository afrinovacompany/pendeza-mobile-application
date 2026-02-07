import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:pendeza/app/config/platform_config.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_theme.dart';

/// Adaptive theme utilities that provide platform-aware theming.
/// Uses AppTheme for base themes and extends with platform-specific helpers.
class AdaptiveTheme {
  AdaptiveTheme._();

  //==========================================================================
  // THEME GETTERS - Based on current platform
  //==========================================================================

  /// Returns the appropriate light theme for the current platform
  static dynamic get lightTheme => PlatformConfig.useCupertino
      ? AppTheme.cupertinoLightTheme
      : AppTheme.lightTheme;

  /// Returns the appropriate dark theme for the current platform
  static dynamic get darkTheme => PlatformConfig.useCupertino
      ? AppTheme.cupertinoDarkTheme
      : AppTheme.darkTheme;

  //==========================================================================
  // MATERIAL THEME DATA
  //==========================================================================

  static ThemeData get materialLight => AppTheme.lightTheme;
  static ThemeData get materialDark => AppTheme.darkTheme;

  //==========================================================================
  // CUPERTINO THEME DATA
  //==========================================================================

  static CupertinoThemeData get cupertinoLight => AppTheme.cupertinoLightTheme;
  static CupertinoThemeData get cupertinoDark => AppTheme.cupertinoDarkTheme;

  //==========================================================================
  // ADAPTIVE COLOR GETTERS
  //==========================================================================

  /// Primary color based on brightness
  static Color primaryColor(BuildContext context) {
    return _isDark(context) ? AppColors.primaryLight : AppColors.primary;
  }

  /// Secondary/accent color based on brightness
  static Color accentColor(BuildContext context) {
    return _isDark(context) ? AppColors.accent2 : AppColors.accent;
  }

  /// Background color based on brightness
  static Color backgroundColor(BuildContext context) {
    return _isDark(context) ? AppColors.darkBackground : AppColors.background;
  }

  /// Surface color based on brightness
  static Color surfaceColor(BuildContext context) {
    return _isDark(context) ? AppColors.darkSurface : AppColors.surface;
  }

  /// Card/elevated surface color
  static Color cardColor(BuildContext context) {
    return _isDark(context) ? AppColors.darkSurfaceVariant : AppColors.surface;
  }

  /// Primary text color based on brightness
  static Color textPrimaryColor(BuildContext context) {
    return _isDark(context) ? AppColors.darkTextPrimary : AppColors.textPrimary;
  }

  /// Secondary text color based on brightness
  static Color textSecondaryColor(BuildContext context) {
    return _isDark(context)
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
  }

  /// Tertiary/hint text color based on brightness
  static Color textTertiaryColor(BuildContext context) {
    return _isDark(context) ? AppColors.darkTextTertiary : AppColors.textLight;
  }

  /// Border color based on brightness
  static Color borderColor(BuildContext context) {
    return _isDark(context) ? AppColors.darkBorder : AppColors.border;
  }

  /// Divider color based on brightness
  static Color dividerColor(BuildContext context) {
    return _isDark(context)
        ? AppColors.darkBorder.withAlpha(128)
        : AppColors.border;
  }

  //==========================================================================
  // ADAPTIVE SEMANTIC COLORS
  //==========================================================================

  static Color successColor(BuildContext context) {
    return _isDark(context) ? AppColors.successLight : AppColors.success;
  }

  static Color errorColor(BuildContext context) {
    return _isDark(context) ? AppColors.errorLight : AppColors.error;
  }

  static Color warningColor(BuildContext context) {
    return _isDark(context) ? AppColors.warningLight : AppColors.warning;
  }

  static Color infoColor(BuildContext context) {
    return _isDark(context) ? AppColors.infoLight : AppColors.info;
  }

  //==========================================================================
  // ADAPTIVE GRADIENTS
  //==========================================================================

  static LinearGradient primaryGradient(BuildContext context) {
    return _isDark(context)
        ? AppColors.darkPrimaryGradient
        : AppColors.primaryGradient;
  }

  static LinearGradient surfaceGradient(BuildContext context) {
    return _isDark(context)
        ? AppColors.darkSurfaceGradient
        : const LinearGradient(
            colors: [AppColors.surface, AppColors.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
  }

  //==========================================================================
  // ADAPTIVE SHADOWS
  //==========================================================================

  static List<BoxShadow> shadowSmall(BuildContext context) {
    return _isDark(context) ? AppColors.darkShadowSm : AppColors.lightShadowSm;
  }

  static List<BoxShadow> shadowMedium(BuildContext context) {
    return _isDark(context) ? AppColors.darkShadowMd : AppColors.lightShadowMd;
  }

  static List<BoxShadow> shadowLarge(BuildContext context) {
    return _isDark(context) ? AppColors.darkShadowLg : AppColors.lightShadowLg;
  }

  //==========================================================================
  // ADAPTIVE DECORATIONS
  //==========================================================================

  static BoxDecoration cardDecoration(BuildContext context) {
    return _isDark(context)
        ? AppColors.darkCardDecoration
        : AppColors.cardDecoration;
  }

  static BoxDecoration elevatedCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: cardColor(context),
      borderRadius: BorderRadius.circular(16),
      boxShadow: shadowMedium(context),
    );
  }

  static BoxDecoration gradientButtonDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: primaryGradient(context),
      borderRadius: BorderRadius.circular(12),
      boxShadow: shadowMedium(context),
    );
  }

  //==========================================================================
  // PLATFORM-ADAPTIVE VALUES
  //==========================================================================

  /// Returns platform-specific border radius
  static BorderRadius get adaptiveBorderRadius => PlatformConfig.useCupertino
      ? BorderRadius.circular(10)
      : BorderRadius.circular(12);

  /// Returns platform-specific card border radius
  static BorderRadius get adaptiveCardRadius => PlatformConfig.useCupertino
      ? BorderRadius.circular(12)
      : BorderRadius.circular(16);

  /// Returns platform-specific button border radius
  static BorderRadius get adaptiveButtonRadius => PlatformConfig.useCupertino
      ? BorderRadius.circular(8)
      : BorderRadius.circular(12);

  /// Returns platform-specific input border radius
  static BorderRadius get adaptiveInputRadius => PlatformConfig.useCupertino
      ? BorderRadius.circular(8)
      : BorderRadius.circular(12);

  /// Returns platform-specific padding
  static EdgeInsets get adaptivePagePadding => PlatformConfig.useCupertino
      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
      : const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  /// Returns platform-specific card padding
  static EdgeInsets get adaptiveCardPadding => PlatformConfig.useCupertino
      ? const EdgeInsets.all(12)
      : const EdgeInsets.all(16);

  /// Returns platform-specific button padding
  static EdgeInsets get adaptiveButtonPadding => PlatformConfig.useCupertino
      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
      : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);

  /// Returns platform-specific list item padding
  static EdgeInsets get adaptiveListItemPadding => PlatformConfig.useCupertino
      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
      : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  //==========================================================================
  // PLATFORM-SPECIFIC WIDGET STYLING
  //==========================================================================

  /// Returns platform-specific app bar elevation
  static double get adaptiveAppBarElevation =>
      PlatformConfig.useCupertino ? 0 : 1;

  /// Returns platform-specific card elevation
  static double get adaptiveCardElevation =>
      PlatformConfig.useCupertino ? 0 : 2;

  /// Returns platform-specific button elevation
  static double get adaptiveButtonElevation =>
      PlatformConfig.useCupertino ? 0 : 4;

  /// Returns platform-specific icon size
  static double get adaptiveIconSize => PlatformConfig.useCupertino ? 22 : 24;

  /// Returns platform-specific small icon size
  static double get adaptiveSmallIconSize =>
      PlatformConfig.useCupertino ? 18 : 20;

  //==========================================================================
  // INPUT DECORATION
  //==========================================================================

  /// Returns adaptive input decoration for text fields
  static InputDecoration adaptiveInputDecoration(
    BuildContext context, {
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final isDark = _isDark(context);

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
      labelStyle: TextStyle(
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
      hintStyle: TextStyle(
        color: isDark ? AppColors.darkTextTertiary : AppColors.textLight,
      ),
      contentPadding: adaptiveCardPadding,
      border: OutlineInputBorder(
        borderRadius: adaptiveInputRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: adaptiveInputRadius,
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: adaptiveInputRadius,
        borderSide: BorderSide(
          color: isDark ? AppColors.primaryLight : AppColors.primary,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: adaptiveInputRadius,
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: adaptiveInputRadius,
        borderSide: const BorderSide(color: AppColors.error, width: 2.0),
      ),
    );
  }

  //==========================================================================
  // CUPERTINO-SPECIFIC HELPERS
  //==========================================================================

  /// Returns CupertinoThemeData from current context (iOS only)
  static CupertinoThemeData? cupertinoThemeOf(BuildContext context) {
    if (!PlatformConfig.useCupertino) return null;
    return CupertinoTheme.of(context);
  }

  /// Returns a Cupertino-style box decoration for iOS
  static BoxDecoration cupertinoCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: cardColor(context),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: borderColor(context).withAlpha(128),
        width: 0.5,
      ),
    );
  }

  //==========================================================================
  // HELPER METHODS
  //==========================================================================

  /// Check if current theme is dark mode
  static bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Public method to check dark mode
  static bool isDarkMode(BuildContext context) => _isDark(context);

  /// Returns a value based on current brightness
  static T brightness<T>(
    BuildContext context, {
    required T light,
    required T dark,
  }) {
    return _isDark(context) ? dark : light;
  }

  /// Returns a value based on platform and brightness
  static T adaptive<T>(
    BuildContext context, {
    required T materialLight,
    required T materialDark,
    required T cupertinoLight,
    required T cupertinoDark,
  }) {
    if (PlatformConfig.useCupertino) {
      return _isDark(context) ? cupertinoDark : cupertinoLight;
    }
    return _isDark(context) ? materialDark : materialLight;
  }
}
