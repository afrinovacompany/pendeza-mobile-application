import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the application's theme mode (system / light / dark).
///
/// The choice is remembered across launches.
class ThemeCubit extends Cubit<ThemeMode> {
  static const _prefsKey = 'theme_mode';

  /// The initial theme follows the system theme mode until a saved choice
  /// has been read.
  ThemeCubit() : super(ThemeMode.system) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
      if (mode != null && !isClosed) emit(mode);
    } catch (_) {
      // No storage available: keep following the system theme.
    }
  }

  Future<void> _save(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (_) {
      // Non-fatal: the choice just won't survive a restart.
    }
  }

  /// Cycles system → light → dark → system.
  void toggleTheme() {
    setThemeMode(switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    });
  }

  /// Sets a specific theme mode and remembers it.
  void setThemeMode(ThemeMode mode) {
    if (mode == state) return;
    emit(mode);
    _save(mode);
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
