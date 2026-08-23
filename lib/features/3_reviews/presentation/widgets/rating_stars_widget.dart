import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';

/// A versatile widget for displaying or inputting star ratings.
///
/// Usage:
/// - Read-only: `RatingStars.display(rating: 4.5)`
/// - Input: `RatingStars.input(onRatingChanged: (val) => ...)`
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final bool isInteractive;
  final Function(double)? onRatingChanged;
  final MainAxisAlignment alignment;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 24,
    this.color,
    this.isInteractive = false,
    this.onRatingChanged,
    this.alignment = MainAxisAlignment.start,
  });

  /// Factory for display-only stars
  factory RatingStars.display({
    required double rating,
    double size = 16,
    Color? color,
    MainAxisAlignment alignment = MainAxisAlignment.start,
  }) {
    return RatingStars(
      rating: rating,
      size: size,
      color: color,
      isInteractive: false,
      alignment: alignment,
    );
  }

  /// Factory for interactive input stars
  factory RatingStars.input({
    required Function(double) onRatingChanged,
    double initialRating = 0,
    double size = 32,
    Color? color,
    MainAxisAlignment alignment = MainAxisAlignment.center,
  }) {
    return RatingStars(
      rating: initialRating,
      size: size,
      color: color,
      isInteractive: true,
      onRatingChanged: onRatingChanged,
      alignment: alignment,
    );
  }

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? const Color(0xFFFFB400); // Amber/Gold

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData iconData = Icons.star_rounded;

        if (rating >= starValue) {
          iconData = Icons.star_rounded;
        } else if (rating >= starValue - 0.5) {
          iconData = Icons.star_half_rounded;
        } else {
          iconData = Icons.star_outline_rounded;
        }

        final icon = Icon(
          iconData,
          size: size,
          color: starColor,
        );

        if (isInteractive) {
          return GestureDetector(
            onTap: () => onRatingChanged?.call(starValue.toDouble()),
            child: icon,
          );
        }

        return icon;
      }),
    );
  }
}

/// A widget that shows the numeric rating, stars, and review count.
/// Example: "4.8 ⭐⭐⭐⭐⭐ (124 reviews)"
class RatingWithText extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final TextStyle? textStyle;
  final double starSize;

  const RatingWithText({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.textStyle,
    this.starSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = textStyle ?? theme.textTheme.bodyMedium;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rating.toStringAsFixed(1),
          style: style?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        RatingStars.display(rating: rating, size: starSize),
        const SizedBox(width: 4),
        Text(
          '($reviewCount)',
          style: style?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// An interactive rating input widget with a label.
class RatingInput extends StatelessWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final String label;

  const RatingInput({
    super.key,
    required this.initialRating,
    required this.onRatingChanged,
    this.label = 'Rate your experience',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppConstants.padS),
        RatingStars.input(
          initialRating: initialRating,
          onRatingChanged: onRatingChanged,
          size: 40,
        ),
        const SizedBox(height: 8),
        Text(
          _getRatingLabel(initialRating),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getRatingLabel(double rating) {
    if (rating == 0) return 'Tap stars to rate';
    if (rating <= 1) return 'Poor';
    if (rating <= 2) return 'Fair';
    if (rating <= 3) return 'Good';
    if (rating <= 4) return 'Very Good';
    return 'Excellent!';
  }
}

/// A bar chart showing the distribution of ratings (5 star, 4 star, etc.)
class RatingDistributionChart extends StatelessWidget {
  final Map<int, int> distribution; // {5: 10, 4: 5, ...}
  final int totalReviews;

  const RatingDistributionChart({
    super.key,
    required this.distribution,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    if (totalReviews == 0) return const SizedBox.shrink();

    return Column(
      children: [5, 4, 3, 2, 1].map((star) {
        final count = distribution[star] ?? 0;
        final percentage = totalReviews > 0 ? count / totalReviews : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              // Star label (e.g. "5")
              SizedBox(
                width: 12,
                child: Text(
                  '$star',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star_rounded, size: 12, color: Colors.grey),
              const SizedBox(width: 8),

              // Progress Bar
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB400)),
                  ),
                ),
              ),

              // Count label (e.g. "10")
              SizedBox(
                width: 30,
                child: Text(
                  '$count',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}