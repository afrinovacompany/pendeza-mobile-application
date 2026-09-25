import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../data/models/review_model.dart';
import '../widgets/rating_stars_widget.dart';

/// A card widget that displays a single review with:
/// - User info (name, photo, verified badge)
/// - Rating stars
/// - Review text
/// - Timestamp
/// - Owner reply (if any)
/// - Edit/Delete options (if user owns the review)
class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final String? currentUserId;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;
  final VoidCallback? onDeleteReply;

  const ReviewCard({
    super.key,
    required this.review,
    this.currentUserId,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
    this.onReply,
    this.onDeleteReply,
  });

  /// Check if current user is the review author
  bool get isReviewAuthor => currentUserId == review.userId;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfoRow(context),
          const SizedBox(height: 12),
          Row(
            children: [
              RatingStars.display(rating: review.rating, size: 17),
              const Spacer(),
              Icon(
                CupertinoIcons.clock,
                size: 12,
                color: ClientTheme.textSecondary(context),
              ),
              const SizedBox(width: 4),
              Text(
                timeago.format(review.createdAt),
                style: ClientTheme.caption(context),
              ),
              if (review.isEdited) ...[
                const SizedBox(width: 6),
                Text(
                  '(${'client.salon_details.edited'.tr()})',
                  style: ClientTheme.caption(context).copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: ClientTheme.body(context).copyWith(
                height: 1.55,
                color: ClientTheme.textPrimary(context),
              ),
            ),
          ],
          if (review.hasOwnerReply) ...[
            const SizedBox(height: 14),
            _buildOwnerReply(context),
          ],
          if (isOwner && !review.hasOwnerReply && onReply != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onReply,
              icon: const Icon(CupertinoIcons.reply, size: 16),
              label: Text('client.salon_details.reply'.tr()),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: ClientTheme.isDark(context)
                    ? Theme.of(context).colorScheme.primary
                    : AppColors.primaryDark,
                textStyle: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  //============================================================================
  // USER INFO ROW
  //============================================================================

  Widget _buildUserInfoRow(BuildContext context) {
    return Row(
      children: [
        ProfileAvatar(
          imageUrl: review.userProfilePicture,
          fullName: review.userName,
          radius: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  review.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTheme.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: ClientTheme.textPrimary(context),
                  ),
                ),
              ),
              if (review.isVerifiedBooking) ...[
                const SizedBox(width: 8),
                ClientPill(
                  label: 'client.salon_details.verified'.tr(),
                  color: const Color(0xFF22C55E),
                  icon: CupertinoIcons.checkmark_seal_fill,
                ),
              ],
            ],
          ),
        ),
        if (isReviewAuthor)
          PopupMenuButton<String>(
            icon: Icon(
              CupertinoIcons.ellipsis,
              size: 20,
              color: ClientTheme.textSecondary(context),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'edit' && onEdit != null) {
                onEdit!();
              } else if (value == 'delete' && onDelete != null) {
                onDelete!();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.pencil, size: 18),
                    const SizedBox(width: 10),
                    Text('client.salon_details.edit_review'.tr()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.trash,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'client.salon_details.delete_review'.tr(),
                      style: const TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  //============================================================================
  // OWNER REPLY
  //============================================================================

  Widget _buildOwnerReply(BuildContext context) {
    final dark = ClientTheme.isDark(context);
    final accent = dark
        ? Theme.of(context).colorScheme.primary
        : AppColors.primaryDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: dark ? 0.16 : 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.building_2_fill, size: 15, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'client.salon_details.owner_response'.tr(),
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              if (isOwner && onDeleteReply != null)
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark, size: 15),
                  onPressed: onDeleteReply,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.ownerReply!,
            style: ClientTheme.body(context).copyWith(
              height: 1.5,
              color: ClientTheme.textPrimary(context),
            ),
          ),
          if (review.ownerRepliedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              timeago.format(review.ownerRepliedAt!),
              style: ClientTheme.caption(context),
            ),
          ],
        ],
      ),
    );
  }
}
