import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendeza/app/bloc/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The cubit restores asynchronously; let that settle.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  test('starts on the system theme when nothing was saved', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = ThemeCubit();
    await settle();
    expect(cubit.state, ThemeMode.system);
    await cubit.close();
  });

  test('remembers the chosen mode across launches', () async {
    SharedPreferences.setMockInitialValues({});
    final first = ThemeCubit();
    await settle();
    first.setThemeMode(ThemeMode.dark);
    await settle();
    await first.close();

    // "Relaunch": a new cubit reads what the first one saved.
    final second = ThemeCubit();
    await settle();
    expect(second.state, ThemeMode.dark);
    await second.close();
  });

  test('ignores a corrupt saved value', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});
    final cubit = ThemeCubit();
    await settle();
    expect(cubit.state, ThemeMode.system);
    await cubit.close();
  });

  test('toggleTheme cycles system -> light -> dark -> system', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = ThemeCubit();
    await settle();
    final seen = <ThemeMode>[];
    for (var i = 0; i < 3; i++) {
      cubit.toggleTheme();
      seen.add(cubit.state);
    }
    expect(seen, [ThemeMode.light, ThemeMode.dark, ThemeMode.system]);
    await cubit.close();
  });
}
