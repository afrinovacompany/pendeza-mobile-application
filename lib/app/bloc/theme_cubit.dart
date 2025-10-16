import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A simple Cubit to manage the application's theme (light/dark mode).
///
/// It holds the current ThemeMode and provides a method to toggle it.
class ThemeCubit extends Cubit<ThemeMode> {
  /// The initial theme is set to light mode.
  ThemeCubit() : super(ThemeMode.light);

  /// Toggles the theme between light and dark mode.
  void toggleTheme() {
    // A simple conditional to switch the state.
    final newThemeMode = (state == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
    emit(newThemeMode);
  }
}
