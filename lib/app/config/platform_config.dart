import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform detection utilities for the app.
/// Provides constants and helper methods to check the current platform.
class PlatformConfig {
  PlatformConfig._();

  /// Whether the app is running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Whether the app is running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Whether the app is running on mobile (iOS or Android)
  static bool get isMobile => isIOS || isAndroid;

  /// Whether the app is running on the web
  static bool get isWeb => kIsWeb;

  /// Whether the app is running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Whether the app is running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Whether the app is running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Whether the app is running on desktop (macOS, Windows, or Linux)
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  /// Whether to use Cupertino (iOS-style) widgets
  static bool get useCupertino => isIOS || isMacOS;

  /// Whether to use Material (Android-style) widgets
  static bool get useMaterial => !useCupertino;

  /// Returns a value based on the current platform
  static T platformSelect<T>({
    required T material,
    required T cupertino,
  }) {
    return useCupertino ? cupertino : material;
  }

  /// Returns the platform name as a string
  static String get platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}

/// Convenience constants for platform checks
const bool kIsWebPlatform = kIsWeb;
