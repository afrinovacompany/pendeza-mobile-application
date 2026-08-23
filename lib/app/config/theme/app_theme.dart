import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// The main theme configuration for the entire application.
///
/// Light and dark [ThemeData] share Poppins typography and a complete
/// Material 3 [ColorScheme] seeded from the brand purple, with existing
/// brand/semantic colors preserved as overrides.
class AppTheme {
  AppTheme._();

  //==========================================================================
  // MATERIAL 3 COLOR SCHEMES
  //==========================================================================

  /// Light ColorScheme generated from the brand seed, with brand overrides.
  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryLight,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.accent,
    onSecondary: AppColors.textPrimary,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: AppColors.errorLight,
    onErrorContainer: AppColors.textPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.background,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surface,
    surfaceContainerHighest: AppColors.surface,
    inversePrimary: AppColors.primaryLight,
    surfaceTint: AppColors.primary,
  );

  /// Dark ColorScheme generated from the same seed, with brand dark overrides.
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: Brightness.dark,
    primary: AppColors.primaryLight,
    onPrimary: AppColors.darkOnPrimary,
    primaryContainer: AppColors.primaryDark,
    onPrimaryContainer: AppColors.primaryLight,
    secondary: AppColors.accent2,
    onSecondary: AppColors.darkOnSecondary,
    error: AppColors.error,
    onError: AppColors.darkOnError,
    errorContainer: AppColors.error,
    onErrorContainer: AppColors.darkOnError,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    onSurfaceVariant: AppColors.darkTextSecondary,
    outline: AppColors.darkBorder,
    outlineVariant: AppColors.darkBorder,
    surfaceContainerLowest: AppColors.darkBackground,
    surfaceContainerLow: AppColors.darkSurface,
    surfaceContainer: AppColors.darkSurface,
    surfaceContainerHigh: AppColors.darkSurfaceVariant,
    surfaceContainerHighest: AppColors.darkSurfaceVariant,
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.primaryLight,
  );

  //==========================================================================
  // LIGHT THEME CONFIGURATION
  //==========================================================================
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: lightColorScheme,
    primaryColor: lightColorScheme.primary,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: AppTextStyles.fontFamily,
    textTheme: _textTheme(
      textColor: AppColors.textPrimary,
      subtitleColor: AppColors.textSecondary,
    ),
    appBarTheme: _appBarTheme(
      backgroundColor: AppColors.primary,
      iconColor: Colors.white,
    ),
    elevatedButtonTheme: _elevatedButtonTheme(
      backgroundColor: lightColorScheme.primary,
      foregroundColor: lightColorScheme.onPrimary,
    ),
    floatingActionButtonTheme: _fabTheme(
      backgroundColor: lightColorScheme.primary,
      foregroundColor: lightColorScheme.onPrimary,
    ),
    cardTheme: _cardTheme(
      color: AppColors.surface,
      shadowColor: Colors.black12,
    ),
    inputDecorationTheme: _inputDecorationTheme(
      fillColor: AppColors.surface,
      borderColor: AppColors.border,
      labelColor: AppColors.textSecondary,
    ),
    pageTransitionsTheme: _pageTransitionsTheme,
  );

  //==========================================================================
  // DARK THEME CONFIGURATION
  //==========================================================================
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: darkColorScheme,
    primaryColor: darkColorScheme.primary,
    scaffoldBackgroundColor: AppColors.darkBackground,
    fontFamily: AppTextStyles.fontFamily,
    textTheme: _textTheme(
      textColor: AppColors.darkOnBackground,
      subtitleColor: AppColors.textLight,
    ),
    appBarTheme: _appBarTheme(
      backgroundColor: AppColors.darkSurface,
      iconColor: Colors.white,
    ),
    elevatedButtonTheme: _elevatedButtonTheme(
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
    ),
    floatingActionButtonTheme: _fabTheme(
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
    ),
    cardTheme: _cardTheme(
      color: AppColors.darkSurface,
      shadowColor: Colors.black.withValues(alpha: 0.4),
    ),
    inputDecorationTheme: _inputDecorationTheme(
      fillColor: AppColors.darkSurface,
      borderColor: AppColors.darkBorder,
      labelColor: AppColors.textLight,
    ),
    pageTransitionsTheme: _pageTransitionsTheme,
  );

  //==========================================================================
  // CUPERTINO LIGHT THEME CONFIGURATION
  //==========================================================================
  static final CupertinoThemeData cupertinoLightTheme = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    primaryContrastingColor: Colors.white,
    scaffoldBackgroundColor: AppColors.background,
    barBackgroundColor: AppColors.surface,
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.primary,
      textStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      actionTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
      navTitleTextStyle: AppTextStyles.appBarTitle.copyWith(color: AppColors.textPrimary),
      navLargeTitleTextStyle: AppTextStyles.headline1.copyWith(color: AppColors.textPrimary),
      navActionTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
      tabLabelTextStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
    ),
  );

  //==========================================================================
  // CUPERTINO DARK THEME CONFIGURATION
  //==========================================================================
  static final CupertinoThemeData cupertinoDarkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryLight,
    primaryContrastingColor: AppColors.darkOnPrimary,
    scaffoldBackgroundColor: AppColors.darkBackground,
    barBackgroundColor: AppColors.darkSurface,
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.primaryLight,
      textStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkOnBackground),
      actionTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryLight),
      navTitleTextStyle: AppTextStyles.appBarTitle.copyWith(color: AppColors.darkOnBackground),
      navLargeTitleTextStyle: AppTextStyles.headline1.copyWith(color: AppColors.darkOnBackground),
      navActionTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryLight),
      tabLabelTextStyle: AppTextStyles.caption.copyWith(color: AppColors.textLight),
    ),
  );

  //==========================================================================
  // SHARED HELPER METHODS FOR THEME COMPONENTS
  //==========================================================================

  static TextTheme _textTheme({required Color textColor, required Color subtitleColor}) {
    return TextTheme(
      displayLarge: AppTextStyles.headline1.copyWith(color: textColor),
      displayMedium: AppTextStyles.headline2.copyWith(color: textColor),
      displaySmall: AppTextStyles.headline3.copyWith(color: textColor),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: textColor),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: textColor),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: textColor),
      labelLarge: AppTextStyles.button,
      labelMedium: AppTextStyles.caption.copyWith(color: subtitleColor),
      titleLarge: AppTextStyles.appBarTitle,
      titleMedium: AppTextStyles.subtitle.copyWith(color: subtitleColor),
    );
  }

  static AppBarTheme _appBarTheme({required Color backgroundColor, required Color iconColor}) {
    return AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 1,
      centerTitle: true,
      iconTheme: IconThemeData(color: iconColor),
      titleTextStyle: AppTextStyles.appBarTitle,
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme({
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: AppTextStyles.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: backgroundColor.withValues(alpha: 0.3),
      ),
    );
  }

  static FloatingActionButtonThemeData _fabTheme({
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return FloatingActionButtonThemeData(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  static CardThemeData _cardTheme({required Color color, required Color shadowColor}) {
    return CardThemeData(
      color: color,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: shadowColor,
      clipBehavior: Clip.antiAlias,
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color fillColor,
    required Color borderColor,
    required Color labelColor,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: AppTextStyles.caption.copyWith(color: labelColor),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: labelColor.withValues(alpha: 0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2.0),
      ),
    );
  }

  static const PageTransitionsTheme _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );
}
