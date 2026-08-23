import 'package:flutter/material.dart';

/// App-wide typography.
///
/// Poppins is the single font family. Weights already in use are preserved
/// (Regular, Medium, SemiBold, Bold, Light).
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Poppins';

  // Headline styles
  static const TextStyle headline1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    fontSize: 32,
    height: 1.3,
  );

  static const TextStyle headline2 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 28,
    height: 1.3,
  );

  static const TextStyle headline3 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 24,
    height: 1.3,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 18,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.5,
  );

  // Caption / Label
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w300,
    fontSize: 12,
    height: 1.4,
  );

  // Button text
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: 1.2,
  );

  // AppBar title
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 20,
  );

  // Light subtitle
  static const TextStyle subtitle = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w300,
    fontSize: 14,
    color: Colors.grey,
  );
}
