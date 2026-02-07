import 'package:flutter/material.dart';

/// A mixin that prevents double navigation by tracking navigation state.
///
/// Use this mixin on StatefulWidget State classes that perform navigation.
/// Call [guardedNavigate] instead of direct navigation calls to prevent
/// the "_debugLocked" assertion error from rapid button taps.
///
/// Example:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with NavigationGuard {
///   void _goToNextScreen() {
///     guardedNavigate(() {
///       context.push('/next-screen');
///     });
///   }
/// }
/// ```
mixin NavigationGuard<T extends StatefulWidget> on State<T> {
  bool _isNavigating = false;

  /// Executes navigation callback only if no navigation is in progress.
  /// Automatically resets after a short delay to handle edge cases.
  void guardedNavigate(VoidCallback navigate) {
    if (_isNavigating || !mounted) return;

    _isNavigating = true;
    navigate();

    // Reset after animation completes to allow future navigation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _isNavigating = false;
      }
    });
  }

  /// Executes an async navigation callback with guard protection.
  Future<void> guardedNavigateAsync(Future<void> Function() navigate) async {
    if (_isNavigating || !mounted) return;

    _isNavigating = true;
    try {
      await navigate();
    } finally {
      // Reset after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _isNavigating = false;
        }
      });
    }
  }

  /// Returns true if navigation is currently blocked
  bool get isNavigating => _isNavigating;
}

/// A simpler approach using a static debouncer for StatelessWidgets
/// or widgets that can't use the mixin.
class NavigationDebouncer {
  static final Map<String, DateTime> _lastNavigationTimes = {};
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  /// Returns true if navigation should proceed, false if debounced.
  /// Use a unique [key] per navigation action (e.g., screen name or button id).
  static bool shouldNavigate(String key) {
    final now = DateTime.now();
    final lastTime = _lastNavigationTimes[key];

    if (lastTime != null && now.difference(lastTime) < _debounceDuration) {
      return false;
    }

    _lastNavigationTimes[key] = now;
    return true;
  }

  /// Clears the debounce state for a specific key
  static void clear(String key) {
    _lastNavigationTimes.remove(key);
  }

  /// Clears all debounce states
  static void clearAll() {
    _lastNavigationTimes.clear();
  }
}
