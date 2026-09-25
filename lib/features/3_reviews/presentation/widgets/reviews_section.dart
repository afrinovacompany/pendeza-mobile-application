import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_bloc.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_event.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_state.dart';
import 'package:pendeza/features/3_reviews/presentation/widgets/review_card.dart';
import 'package:pendeza/features/3_reviews/presentation/widgets/review_summary_card.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class ReviewsSection extends StatelessWidget {
  final SalonModel salon;

  const ReviewsSection({super.key, required this.salon});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewsBloc, ReviewsState>(
      builder: (context, state) {
        if (state is ReviewsLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ReviewsEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: ClientEmptyState(
              icon: CupertinoIcons.star,
              title: 'client.salon_details.no_reviews_title'.tr(),
              message: 'client.salon_details.no_reviews_msg'.tr(),
              actionLabel: 'client.salon_details.write_review'.tr(),
              onAction: () => _handleWriteReview(context),
              color: const Color(0xFFF5A623),
            ),
          );
        }

        if (state is ReviewsLoaded) {
          return _buildLoadedState(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadedState(BuildContext context, ReviewsLoaded state) {
    final previewReviews = state.reviews.take(3).toList();
    final authState = context.read<AuthBloc>().state;
    String? currentUserId;
    bool isOwner = false;

    if (authState is Authenticated) {
      currentUserId = authState.user.uid;
      isOwner = authState.user.uid == salon.ownerId;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'client.salon_details.tab_reviews'.tr(),
                  style: ClientTheme.title(context),
                ),
              ),
              _WriteReviewButton(onTap: () => _handleWriteReview(context)),
            ],
          ),
          const SizedBox(height: 14),
          ReviewSummaryCard(
            averageRating: state.averageRating,
            totalReviews: state.totalReviews,
            distribution: state.ratingDistribution,
          ),
          const SizedBox(height: 16),
          for (final review in previewReviews) ...[
            ReviewCard(
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
                CustomSnackBar.show(
                  context,
                  message: 'client.salon_details.reply_soon'.tr(),
                  type: SnackBarType.info,
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          if (state.totalReviews > 3)
            OutlinedButton(
              onPressed: () {
                context.push(
                  AppRoutes.salonReviews.replaceFirst(':salonId', salon.id),
                  extra: salon,
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 50),
                foregroundColor: ClientTheme.isDark(context)
                    ? Theme.of(context).colorScheme.primary
                    : AppColors.primaryDark,
                side: BorderSide(color: ClientTheme.border(context)),
                textStyle: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'client.salon_details.see_all_n'
                    .tr(args: ['${state.totalReviews}']),
              ),
            ),
        ],
      ),
    );
  }

  void _handleWriteReview(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    if (authState is! Authenticated) {
      CustomSnackBar.show(
        context,
        message: 'client.salon_details.sign_in_to_review'.tr(),
        type: SnackBarType.info,
      );
      return;
    }

    context.push(
      AppRoutes.writeReview.replaceFirst(':salonId', salon.id),
    );
  }
}

class _WriteReviewButton extends StatelessWidget {
  final VoidCallback onTap;

  const _WriteReviewButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = ClientTheme.isDark(context);
    final accent =
        dark ? Theme.of(context).colorScheme.primary : AppColors.primaryDark;

    return Material(
      color: AppColors.primary.withValues(alpha: dark ? 0.2 : 0.10),
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.pencil, size: 15, color: accent),
              const SizedBox(width: 6),
              Text(
                'client.salon_details.write_review'.tr(),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
