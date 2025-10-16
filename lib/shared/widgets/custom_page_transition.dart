import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A custom page transition that uses a fade effect.
///
/// This helps to avoid the brief appearance of an intermediate colored screen
/// during navigation, providing a smoother user experience.
class CustomPageTransition<T> extends CustomTransitionPage<T> {
  CustomPageTransition({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Use a simple FadeTransition for a clean and smooth effect.
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
