import 'package:flutter/material.dart';
import '../../app/config/theme/app_constants.dart';

/// A custom, reusable card widget for the application.
///
/// This card standardizes the look and feel by using predefined decorations,
/// shadows, and border radiuses from the app's theme. It automatically
/// adapts its appearance for light and dark modes.
class CustomCard extends StatelessWidget {
  /// The content to display inside the card.
  final Widget child;

  /// The callback that is called when the card is tapped.
  /// If null, the card will not have a ripple effect.
  final VoidCallback? onTap;

  /// The padding inside the card. Defaults to a medium padding (`AppConstants.padM`).
  final EdgeInsets? padding;

  /// An optional gradient to override the default.
  final Gradient? gradient;

  /// An optional color to override the default.
  final Color? color;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.gradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Determine the card's decoration based on the theme and provided properties.
    final BoxDecoration decoration = BoxDecoration(
      gradient: gradient, // Use override gradient if provided
      // If no gradient override, use a specific color or the theme's default card color
      color: gradient == null ? (color ?? theme.cardTheme.color) : null,
      borderRadius: AppConstants.radiusL, // Use large radius for cards
      boxShadow: [
        // Use a subtle, theme-aware shadow
        BoxShadow(
          color: theme.cardTheme.shadowColor ?? Colors.black.withOpacity(0.1),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: -2,
        ),
      ],
    );

    return Container(
      // Apply the decoration to the outer container.
      decoration: decoration,
      // Use Clip.antiAlias to ensure the child (and InkWell ripple)
      // respects the rounded corners of the card.
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Only enable the tap functionality if an onTap callback is provided.
          onTap: onTap,
          child: Padding(
            // Use the provided padding, or default to a medium padding.
            padding: padding ?? const EdgeInsets.all(AppConstants.padM),
            child: child,
          ),
        ),
      ),
    );
  }
}
