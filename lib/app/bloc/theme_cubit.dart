import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A simple Cubit to manage the application's theme (light/dark mode).
///
/// It holds the current ThemeMode and provides a method to toggle it.
class ThemeCubit extends Cubit<ThemeMode> {
  /// The initial theme follows the system theme mode.
  ThemeCubit() : super(ThemeMode.system);

  /// Toggles the theme between light, dark, and system mode.
  void toggleTheme() {
    final newThemeMode = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    emit(newThemeMode);
  }

  /// Sets a specific theme mode.
  void setThemeMode(ThemeMode mode) {
    emit(mode);
  }

  /// Returns true if currently using system theme.
  bool get isSystemTheme => state == ThemeMode.system;

  /// Returns true if currently in dark mode (either explicit or system dark).
  bool isDark(BuildContext context) {
    if (state == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return state == ThemeMode.dark;
  }
}
