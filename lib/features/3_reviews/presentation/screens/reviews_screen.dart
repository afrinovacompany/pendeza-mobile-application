import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_bloc.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_event.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_state.dart';
import 'package:pendeza/features/3_reviews/presentation/widgets/rating_stars_widget.dart';
import 'package:pendeza/features/3_reviews/presentation/widgets/review_card.dart';
import 'package:pendeza/shared/models/salon_model.dart';

import '../../data/models/review_model.dart';

/// Screen displaying all reviews for a specific salon.
class ReviewsScreen extends StatelessWidget {
  final SalonModel salon;

  const ReviewsScreen({super.key, required this.salon});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ReviewsBloc>()..add(LoadReviews(salonId: salon.id)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reviews'),
          centerTitle: true,
        ),
        body: _ReviewsContent(salon: salon),
        floatingActionButton: _WriteReviewFab(salon: salon),
      ),
    );
  }
}

class _ReviewsContent extends StatelessWidget {
  final SalonModel salon;

  const _ReviewsContent({required this.salon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<ReviewsBloc, ReviewsState>(
      listener: (context, state) {
        if (state is ReviewsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: theme.colorScheme.error),
          );
        }
      },
      builder: (context, state) {
        if (state is ReviewsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ReviewsEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: AppConstants.padM),
                Text(state.message, style: theme.textTheme.bodyLarge),
              ],
            ),
          );
        }

        if (state is ReviewsLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ReviewsBloc>().add(RefreshReviews(salonId: salon.id));
            },
            child: CustomScrollView(
              slivers: [
                // Summary Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.padL),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Big Average Rating
                        Column(
                          children: [
                            Text(
                              state.averageRating.toStringAsFixed(1),
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            RatingStars.display(rating: state.averageRating, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              '${state.totalReviews} reviews',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(width: AppConstants.padXL),
                        // Distribution Chart
                        Expanded(
                          child: RatingDistributionChart(
                            distribution: state.ratingDistribution,
                            totalReviews: state.totalReviews,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Filter/Sort Bar (Optional enhancement)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
                    child: Row(
                      children: [
                        Text('Sort by:', style: theme.textTheme.labelLarge),
                        const SizedBox(width: AppConstants.padS),
                        DropdownButton<String>(
                          value: state.sortBy,
                          underline: const SizedBox(),
                          style: theme.textTheme.bodyMedium,
                          items: const [
                            DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
                            DropdownMenuItem(value: 'highest', child: Text('Highest Rated')),
                            DropdownMenuItem(value: 'lowest', child: Text('Lowest Rated')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              context.read<ReviewsBloc>().add(SortReviews(sortBy: val));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverPadding(padding: EdgeInsets.only(top: AppConstants.padM)),

                // Reviews List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final review = state.reviews[index];
                      final authState = context.read<AuthBloc>().state;
                      String? currentUserId;
                      bool isOwner = false;

                      if (authState is Authenticated) {
                        currentUserId = authState.user.uid;
                        isOwner = authState.user.uid == salon.ownerId;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
                        child: ReviewCard(
                          review: review,
                          currentUserId: currentUserId,
                          isOwner: isOwner,
                          onEdit: () {
                            context.push(
                              AppRoutes.writeReview.replaceFirst(':salonId', salon.id),
                              extra: {'salon': salon, 'review': review},
                            ).then((_) => context.read<ReviewsBloc>().add(RefreshReviews(salonId: salon.id)));
                          },
                          onDelete: () {
                            context.read<ReviewsBloc>().add(
                              DeleteReview(reviewId: review.id, userId: review.userId),
                            );
                          },
                          onReply: () {
                            // Basic dialog for reply
                            _showReplyDialog(context, review);
                          },
                          onDeleteReply: () {
                            context.read<ReviewsBloc>().add(
                              DeleteOwnerReply(reviewId: review.id, ownerId: currentUserId!),
                            );
                          },
                        ),
                      );
                    },
                    childCount: state.reviews.length,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)), // Space for FAB
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _showReplyDialog(BuildContext context, ReviewModel review) {
    final controller = TextEditingController();
    final authState = context.read<AuthBloc>().state;

    if (authState is! Authenticated) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reply to Review'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Write your response...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<ReviewsBloc>().add(
                AddOwnerReply(
                  reviewId: review.id,
                  salonId: salon.id,
                  ownerId: authState.user.uid,
                  replyText: controller.text.trim(),
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Post Reply'),
          ),
        ],
      ),
    );
  }
}

class _WriteReviewFab extends StatelessWidget {
  final SalonModel salon;

  const _WriteReviewFab({required this.salon});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewsBloc, ReviewsState>(
      builder: (context, state) {
        // Don't show FAB if user is not eligible or already reviewed (optional UX choice)
        // For now, we always show it and let the logic handle the check/redirect
        return FloatingActionButton.extended(
          onPressed: () {
            final authState = context.read<AuthBloc>().state;
            if (authState is! Authenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please sign in to write a review')),
              );
              return;
            }

            context.push(
              AppRoutes.writeReview.replaceFirst(':salonId', salon.id),
            ).then((_) {
              // Refresh list after returning
              context.read<ReviewsBloc>().add(RefreshReviews(salonId: salon.id));
            });
          },
          label: const Text('Write Review'),
          icon: const Icon(Icons.rate_review),
        );
      },
    );
  }
}