
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/config/theme/app_constants.dart';

/// Enhanced shimmer placeholder with better animations
class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
  });

  const ShimmerPlaceholder.line({
    super.key,
    required this.width,
    this.height = 16.0,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
  });

  const ShimmerPlaceholder.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        shape = BoxShape.circle,
        borderRadius = null;

  const ShimmerPlaceholder.rectangular({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDarkMode
        ? Colors.grey[850]!
        : Colors.grey[300]!;
    final highlightColor = isDarkMode
        ? Colors.grey[700]!
        : Colors.grey[100]!;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: const Duration(milliseconds: 1200),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor,
            shape: shape,
            borderRadius: (shape == BoxShape.rectangle)
                ? (borderRadius ?? AppConstants.radiusM)
                : null,
          ),
        ),
      ),
    );
  }
}

/// Enhanced loading skeleton for cards
class ShimmerCard extends StatelessWidget {
  final double? height;

  const ShimmerCard({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 100,
      margin: const EdgeInsets.only(bottom: AppConstants.padM),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppConstants.radiusL,
      ),
      padding: const EdgeInsets.all(AppConstants.padM),
      child: Row(
        children: [
          const ShimmerPlaceholder.circle(size: 48),
          const SizedBox(width: AppConstants.padL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerPlaceholder.line(
                  width: double.infinity,
                  height: 16,
                  borderRadius: AppConstants.radiusS,
                ),
                const SizedBox(height: AppConstants.padS),
                ShimmerPlaceholder.line(
                  width: 120,
                  height: 14,
                  borderRadius: AppConstants.radiusS,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Enhanced loading skeleton for list items
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.padL,
        vertical: AppConstants.padS,
      ),
      child: Row(
        children: [
          const ShimmerPlaceholder.circle(size: 40),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerPlaceholder.line(
                  width: double.infinity,
                  height: 14,
                  borderRadius: AppConstants.radiusS,
                ),
                const SizedBox(height: AppConstants.padXS),
                ShimmerPlaceholder.line(
                  width: 100,
                  height: 12,
                  borderRadius: AppConstants.radiusS,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}