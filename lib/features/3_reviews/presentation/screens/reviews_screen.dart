import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_bloc.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_event.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_state.dart';
import 'package:pendeza/features/3_reviews/presentation/widgets/review_card.dart';
import 'package:pendeza/features/3_reviews/presentation/widgets/review_summary_card.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

import '../../data/models/review_model.dart';

/// Screen displaying all reviews for a specific salon.
class ReviewsScreen extends StatelessWidget {
  final SalonModel salon;

  const ReviewsScreen({super.key, required this.salon});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<ReviewsBloc>()..add(LoadReviews(salonId: salon.id)),
      child: Scaffold(
        backgroundColor: ClientTheme.background(context),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ClientPageHeader(
                title: 'client.salon_details.tab_reviews'.tr(),
                subtitle: salon.salonName,
              ),
              Expanded(child: _ReviewsContent(salon: salon)),
            ],
          ),
        ),
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
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ReviewsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ReviewsEmpty) {
          return ClientEmptyState(
            icon: CupertinoIcons.star,
            title: 'client.salon_details.no_reviews_title'.tr(),
            message: 'client.salon_details.no_reviews_msg'.tr(),
            color: const Color(0xFFF5A623),
          );
        }

        if (state is ReviewsLoaded) {
          final authState = context.read<AuthBloc>().state;
          String? currentUserId;
          bool isOwner = false;

          if (authState is Authenticated) {
            currentUserId = authState.user.uid;
            isOwner = authState.user.uid == salon.ownerId;
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<ReviewsBloc>()
                  .add(RefreshReviews(salonId: salon.id));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                ClientTheme.gutter,
                18,
                ClientTheme.gutter,
                100, // room for the FAB
              ),
              children: [
                ReviewSummaryCard(
                  averageRating: state.averageRating,
                  totalReviews: state.totalReviews,
                  distribution: state.ratingDistribution,
                ),
                const SizedBox(height: 16),
                _SortChips(current: state.sortBy),
                const SizedBox(height: 14),
                for (final review in state.reviews) ...[
                  ReviewCard(
                    review: review,
                    currentUserId: currentUserId,
                    isOwner: isOwner,
                    onEdit: () {
                      final bloc = context.read<ReviewsBloc>();
                      context
                          .push(
                            AppRoutes.writeReview
                                .replaceFirst(':salonId', salon.id),
                            extra: {'salon': salon, 'review': review},
                          )
                          .then((_) =>
                              bloc.add(RefreshReviews(salonId: salon.id)));
                    },
                    onDelete: () {
                      context.read<ReviewsBloc>().add(
                            DeleteReview(
                              reviewId: review.id,
                              userId: review.userId,
                            ),
                          );
                    },
                    onReply: () => _showReplyDialog(context, review),
                    onDeleteReply: () {
                      context.read<ReviewsBloc>().add(
                            DeleteOwnerReply(
                              reviewId: review.id,
                              ownerId: currentUserId!,
                            ),
                          );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('client.salon_details.reply_title'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'client.salon_details.reply_hint'.tr(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
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
            child: Text('client.salon_details.post_reply'.tr()),
          ),
        ],
      ),
    );
  }
}

class _SortChips extends StatelessWidget {
  final String current;

  const _SortChips({required this.current});

  @override
  Widget build(BuildContext context) {
    final options = <(String, String)>[
      ('recent', 'client.salon_details.sort_recent'.tr()),
      ('highest', 'client.salon_details.sort_highest'.tr()),
      ('lowest', 'client.salon_details.sort_lowest'.tr()),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, label) in options)
          _SortChip(
            label: label,
            selected: current == value,
            onTap: () =>
                context.read<ReviewsBloc>().add(SortReviews(sortBy: value)),
          ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : ClientTheme.card(context),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? Colors.transparent : ClientTheme.border(context),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : ClientTheme.textPrimary(context),
                ),
              ),
            ),
          ),
        ),
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
                SnackBar(
                  content: Text('client.salon_details.sign_in_to_review'.tr()),
                ),
              );
              return;
            }

            final bloc = context.read<ReviewsBloc>();
            context
                .push(
              AppRoutes.writeReview.replaceFirst(':salonId', salon.id),
            )
                .then((_) {
              // Refresh list after returning
              bloc.add(RefreshReviews(salonId: salon.id));
            });
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          label: Text(
            'client.salon_details.write_review'.tr(),
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: const Icon(CupertinoIcons.pencil),
        );
      },
    );
  }
}
