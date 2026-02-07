import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_bloc.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_event.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_state.dart';
import 'package:pendeza/features/3_reviews/presentation/widgets/rating_stars_widget.dart';
import 'package:pendeza/features/3_reviews/presentation/widgets/review_card.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import '../../../../shared/widgets/custom_snackbar.dart'; // Import

class ReviewsSection extends StatelessWidget {
  final SalonModel salon;

  const ReviewsSection({super.key, required this.salon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ReviewsBloc, ReviewsState>(
      builder: (context, state) {
        if (state is ReviewsLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppConstants.padL),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ReviewsEmpty) {
          return _buildEmptyState(context, theme);
        }

        if (state is ReviewsLoaded) {
          return _buildLoadedState(context, theme, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.padL,
        vertical: AppConstants.padXL,
      ),
      child: Column(
        children: [
          Icon(
            Icons.star_border_rounded,
            size: 48,
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: AppConstants.padM),
          Text(
            'No reviews yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Be the first to share your experience!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.padL),
          OutlinedButton(
            onPressed: () => _handleWriteReview(context),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: AppConstants.radiusM,
              ),
            ),
            child: const Text('Write a Review'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(
      BuildContext context,
      ThemeData theme,
      ReviewsLoaded state,
      ) {
    final previewReviews = state.reviews.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _handleWriteReview(context),
                child: const Text('Write a Review'),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.padM),

          // Summary Card
          _buildSummaryCard(context, theme, state),
          const SizedBox(height: AppConstants.padXL),

          // Reviews List
          ...previewReviews.map((review) {
            final authState = context.read<AuthBloc>().state;
            String? currentUserId;
            bool isOwner = false;

            if (authState is Authenticated) {
              currentUserId = authState.user.uid;
              isOwner = authState.user.uid == salon.ownerId;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.padL),
              child: ReviewCard(
                review: review,
                currentUserId: currentUserId,
                isOwner: isOwner,
                onEdit: () => context.push(
                  AppRoutes.writeReview.replaceFirst(':salonId', salon.id),
                  extra: {'salon': salon, 'review': review},
                ),
                onDelete: () {
                  context.read<ReviewsBloc>().add(
                    DeleteReview(reviewId: review.id, userId: review.userId),
                  );
                },
                onReply: () {
                  // Custom Snackbar for not implemented features too!
                  CustomSnackBar.show(
                      context,
                      message: 'Reply feature coming soon',
                      type: SnackBarType.info
                  );
                },
              ),
            );
          }),

          if (state.totalReviews > 3)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // View all
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: theme.colorScheme.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppConstants.radiusM,
                  ),
                ),
                child: Text('See all ${state.totalReviews} reviews'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, ThemeData theme, ReviewsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: AppConstants.radiusL,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                state.averageRating.toStringAsFixed(1),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              RatingStars.display(
                rating: state.averageRating,
                size: 16,
                color: Colors.amber,
              ),
              const SizedBox(height: 4),
              Text(
                '${state.totalReviews} ratings',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppConstants.padL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [5, 4, 3, 2, 1].map((star) {
                final count = state.ratingDistribution[star] ?? 0;
                final percentage =
                state.totalReviews == 0 ? 0.0 : count / state.totalReviews;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 6,
                            backgroundColor: theme.colorScheme.surface,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.amber,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _handleWriteReview(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    if (authState is! Authenticated) {
      // INFO SNACKBAR
      CustomSnackBar.show(
        context,
        message: 'Please sign in to write a review',
        type: SnackBarType.info,
      );
      return;
    }

    context.push(
      AppRoutes.writeReview.replaceFirst(':salonId', salon.id),
    );
  }
}