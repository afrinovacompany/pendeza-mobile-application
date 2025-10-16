import 'package:flutter/material.dart';

// Import your custom color and text style classes.
import 'app_colors.dart';
import 'app_text_styles.dart';

/// The main theme configuration for the entire application.
/// This class provides separate ThemeData objects for light and dark modes,
/// built from a centralized, professional-grade palette and typography system.
class AppTheme {
  AppTheme._();

  //==========================================================================
  // LIGHT THEME CONFIGURATION
  //==========================================================================
  static final ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.error,
      surface: AppColors.surface,
      onPrimary: Colors.white,
      onSecondary: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),
    fontFamily: 'Poppins',
    textTheme: _textTheme(textColor: AppColors.textPrimary, subtitleColor: AppColors.textSecondary),
    appBarTheme: _appBarTheme(backgroundColor: AppColors.primary, iconColor: Colors.white),
    elevatedButtonTheme: _elevatedButtonTheme(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.textPrimary,
    ),
    floatingActionButtonTheme: _fabTheme(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.textPrimary,
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
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryLight,
    scaffoldBackgroundColor: AppColors.darkBackground,
    // **FIXED**: Using centralized colors from AppColors for the dark theme.
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      secondary: AppColors.accent2,
      error: AppColors.error,
      surface: AppColors.darkSurface,
      onPrimary: AppColors.darkOnPrimary, // Using new centralized color
      onSecondary: AppColors.darkOnSecondary, // Using new centralized color
      onSurface: AppColors.darkOnSurface, // Using new centralized color
      onError: AppColors.darkOnError, // Using new centralized color
    ),
    fontFamily: 'Poppins',
    textTheme: _textTheme(textColor: AppColors.darkOnBackground, subtitleColor: AppColors.textLight),
    appBarTheme: _appBarTheme(backgroundColor: AppColors.darkSurface, iconColor: Colors.white),
    elevatedButtonTheme: _elevatedButtonTheme(
      backgroundColor: AppColors.accent2,
      foregroundColor: AppColors.darkOnSecondary,
    ),
    floatingActionButtonTheme: _fabTheme(
      backgroundColor: AppColors.accent2,
      foregroundColor: AppColors.darkOnSecondary,
    ),
    cardTheme: _cardTheme(
      color: AppColors.darkSurface,
      shadowColor: Colors.black.withOpacity(0.4),
    ),
    inputDecorationTheme: _inputDecorationTheme(
      fillColor: AppColors.darkSurface,
      borderColor: AppColors.darkBorder,
      labelColor: AppColors.textLight,
    ),
    pageTransitionsTheme: _pageTransitionsTheme,
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

  static ElevatedButtonThemeData _elevatedButtonTheme({required Color backgroundColor, required Color foregroundColor}) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: AppTextStyles.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: backgroundColor.withOpacity(0.3),
      ),
    );
  }

  static FloatingActionButtonThemeData _fabTheme({required Color backgroundColor, required Color foregroundColor}) {
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

  static InputDecorationTheme _inputDecorationTheme({required Color fillColor, required Color borderColor, required Color labelColor}) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: AppTextStyles.caption.copyWith(color: labelColor),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: labelColor.withOpacity(0.7)),
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
