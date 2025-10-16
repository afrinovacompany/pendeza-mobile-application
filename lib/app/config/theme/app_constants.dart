import 'package:flutter/material.dart';

/// A class to hold all application-wide constants for UI styling and layout.
///
/// This centralizes values like padding, spacing, border radius, and animation durations,
/// ensuring a consistent look and feel across the entire app and making it easy to
/// update these values globally.
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  //============================================================================
  // PADDING & MARGIN CONSTANTS
  // Use these for consistent spacing inside and outside widgets.
  //============================================================================

  /// 4.0 - Extra small padding, useful for tight spaces.
  static const double padXXS = 4.0;

  /// 8.0 - Small padding, often used for icon buttons or between small elements.
  static const double padXS = 8.0;

  /// 12.0 - A slightly smaller medium padding.
  static const double padS = 12.0;

  /// 16.0 - The default, most common padding value.
  static const double padM = 16.0;

  /// 24.0 - Large padding, for separating major sections.
  static const double padL = 24.0;

  /// 32.0 - Extra large padding, for page-level spacing.
  static const double padXL = 32.0;

  /// 48.0 - Huge padding, for hero sections or significant visual separation.
  static const double padXXL = 48.0;


  //============================================================================
  // BORDER RADIUS CONSTANTS
  // Use these for consistent corner rounding on cards, buttons, etc.
  //============================================================================

  /// 4.0 - Subtle corner rounding.
  static final BorderRadius radiusXS = BorderRadius.circular(4.0);

  /// 8.0 - Small, common corner rounding.
  static final BorderRadius radiusS = BorderRadius.circular(8.0);

  /// 12.0 - The default radius for most buttons and input fields.
  static final BorderRadius radiusM = BorderRadius.circular(12.0);

  /// 16.0 - The default radius for cards.
  static final BorderRadius radiusL = BorderRadius.circular(16.0);

  /// 24.0 - Larger rounding for profile pictures or prominent elements.
  static final BorderRadius radiusXL = BorderRadius.circular(24.0);

  /// A fully circular border radius.
  static final BorderRadius radiusCircular = BorderRadius.circular(100.0);


  //============================================================================
  // ANIMATION & TRANSITION DURATIONS
  //============================================================================

  /// 150ms - For very fast animations, like button feedback.
  static const Duration durationFast = Duration(milliseconds: 150);

  /// 300ms - The standard duration for most UI animations (e.g., fades, slides).
  static const Duration durationMedium = Duration(milliseconds: 300);

  /// 500ms - For slower, more deliberate animations.
  static const Duration durationSlow = Duration(milliseconds: 500);


  //============================================================================
  // ICON SIZES
  //============================================================================

  /// 16.0 - Small icons
  static const double iconSizeS = 16.0;

  /// 24.0 - Standard icon size, default for AppBar actions etc.
  static const double iconSizeM = 24.0;

  /// 32.0 - Large icons, for prominent actions.
  static const double iconSizeL = 32.0;

}
