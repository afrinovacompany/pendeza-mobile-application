import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // PRIMARY COLORS - More vibrant and modern
  static const Color primary = Color(0xFF6C5CE7);  // Brighter purple
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color primaryDark = Color(0xFF5F3DC4);

  // ACCENT COLORS - More cohesive
  static const Color accent = Color(0xFFFAB1A0);  // Warm coral
  static const Color accent2 = Color(0xFF74B9FF);  // Sky blue

  // NEUTRALS - Better contrast
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textLight = Color(0xFFB2BEC3);
  static const Color background = Color(0xFFFDFDFD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDFE6E9);

  // DARK THEME COLORS - Enhanced contrast
  static const Color darkBackground = Color(0xFF0A0E27);  // Deep navy
  static const Color darkSurface = Color(0xFF1A1D3A);
  static const Color darkSurfaceVariant = Color(0xFF252842);  // NEW: For cards/elevated surfaces
  static const Color darkBorder = Color(0xFF2F3349);

  // Dark theme text colors - Better readability
  static const Color darkTextPrimary = Color(0xFFE8EAED);
  static const Color darkTextSecondary = Color(0xFFB8BABD);
  static const Color darkTextTertiary = Color(0xFF9AA0A6);

  // Dark theme scheme colors
  static const Color darkOnPrimary = Color(0xFF000000);
  static const Color darkOnSecondary = Color(0xFF000000);
  static const Color darkOnSurface = Color(0xFFE8EAED);
  static const Color darkOnBackground = Color(0xFFE8EAED);
  static const Color darkOnError = Color(0xFFFFFFFF);

  // SEMANTIC COLORS - More vibrant
  static const Color success = Color(0xFF00B894);
  static const Color successLight = Color(0xFF55EFC4);
  static const Color error = Color(0xFFFF6B6B);
  static const Color errorLight = Color(0xFFFF7675);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color warningLight = Color(0xFFFECE7A);
  static const Color info = Color(0xFF74B9FF);
  static const Color infoLight = Color(0xFF81ECEC);

  // GRADIENTS - More modern and vibrant
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFAB1A0), Color(0xFFF8B500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF55EFC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // NEW: Dark theme gradients
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF8B7DAA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    colors: [Color(0xFF1A1D3A), Color(0xFF252842)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // SHADOWS - Better depth
  // FIXED: Replaced .withOpacity() with .withAlpha()
  static List<BoxShadow> get lightShadowSm => [
    BoxShadow(
      color: Colors.black.withAlpha(10), // 0.04
      offset: const Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  static List<BoxShadow> get lightShadowMd => [
    BoxShadow(
      color: Colors.black.withAlpha(20), // 0.08
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get lightShadowLg => [
    BoxShadow(
      color: Colors.black.withAlpha(31), // 0.12
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get darkShadowSm => [
    BoxShadow(
      color: Colors.black.withAlpha(77), // 0.3
      offset: const Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static List<BoxShadow> get darkShadowMd => [
    BoxShadow(
      color: Colors.black.withAlpha(102), // 0.4
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get darkShadowLg => [
    BoxShadow(
      color: Colors.black.withAlpha(128), // 0.5
      offset: const Offset(0, 8),
      blurRadius: 32,
      spreadRadius: -4,
    ),
  ];

  // DECORATIONS
  static BoxDecoration buttonDecoration = BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(12),
    boxShadow: lightShadowMd,
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: lightShadowSm,
  );

  static BoxDecoration darkCardDecoration = BoxDecoration(
    color: darkSurfaceVariant,
    borderRadius: BorderRadius.circular(16),
    boxShadow: darkShadowSm,
  );
}
