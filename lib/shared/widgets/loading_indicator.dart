import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/config/theme/app_constants.dart';



/// A reusable shimmer effect placeholder widget.
///
/// This widget is used to create skeleton screens or content placeholders
/// while data is being fetched. It automatically adapts its colors for
/// light and dark themes.
class ShimmerPlaceholder extends StatelessWidget {
  /// The width of the placeholder.
  final double width;

  /// The height of the placeholder.
  final double height;

  /// The shape of the placeholder. Defaults to a rounded rectangle.
  final BoxShape shape;

  /// The border radius for the placeholder. Defaults to a medium radius.
  /// This is only used if the shape is a rectangle.
  final BorderRadius? borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
  });

  /// A constructor for creating a rectangular placeholder for a line of text.
  /// Note: This constructor is not 'const' because it uses a non-constant
  /// default value for `borderRadius` from AppConstants.
  const ShimmerPlaceholder.line({
    super.key,
    required this.width,
    this.height = 16.0, // Default height for a line of text
    this.shape = BoxShape.rectangle, this.borderRadius,

  });

  /// A constructor for creating a circular placeholder (e.g., for an avatar).
  const ShimmerPlaceholder.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        shape = BoxShape.circle,
        borderRadius = null;


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define theme-aware colors for the shimmer effect.
    final baseColor = isDarkMode ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor, // The shimmer needs a solid background color
          shape: shape,
          borderRadius: (shape == BoxShape.rectangle)
              ? (borderRadius ?? AppConstants.radiusM)
              : null,
        ),
      ),
    );
  }
}

