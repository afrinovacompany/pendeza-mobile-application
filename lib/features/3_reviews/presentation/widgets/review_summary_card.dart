import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/features/3_reviews/presentation/widgets/rating_stars_widget.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

/// Average rating, star row and per-star distribution of a salon's reviews.
class ReviewSummaryCard extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution;

  const ReviewSummaryCard({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  color: ClientTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 6),
              RatingStars.display(rating: averageRating, size: 16),
              const SizedBox(height: 6),
              Text(
                'client.salon_details.ratings_count'.tr(args: ['$totalReviews']),
                style: ClientTheme.caption(context),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: RatingDistributionChart(
              distribution: distribution,
              totalReviews: totalReviews,
            ),
          ),
        ],
      ),
    );
  }
}
