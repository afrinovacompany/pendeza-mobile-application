import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
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
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.padM),
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppConstants.radiusL,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          _buildUserInfoRow(context, theme),

          const SizedBox(height: AppConstants.padM),

          // Rating stars
          RatingStars.display(
            rating: review.rating,
            size: 18,
          ),

          const SizedBox(height: AppConstants.padS),

          // Review comment
          if (review.comment.isNotEmpty) ...[
            Text(
              review.comment,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppConstants.padS),
          ],

          // Timestamp and edited indicator
          _buildTimestampRow(context, theme),

          // Owner reply section
          if (review.hasOwnerReply) ...[
            const SizedBox(height: AppConstants.padM),
            _buildOwnerReply(context, theme),
          ],

          // Action buttons (edit/delete or reply)
          if (isReviewAuthor || isOwner || !review.hasOwnerReply) ...[
            const SizedBox(height: AppConstants.padS),
            _buildActionButtons(context, theme),
          ],
        ],
      ),
    );
  }

  //============================================================================
  // USER INFO ROW
  //============================================================================

  Widget _buildUserInfoRow(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        // Profile picture
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          backgroundImage: review.userProfilePicture != null
              ? CachedNetworkImageProvider(review.userProfilePicture!)
              : null,
          child: review.userProfilePicture == null
              ? Text(
            review.userName[0].toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          )
              : null,
        ),

        const SizedBox(width: AppConstants.padS),

        // Name and verified badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      review.userName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (review.isVerifiedBooking) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 12,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Verified',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // More menu
        if (isReviewAuthor)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onSelected: (value) {
              if (value == 'edit' && onEdit != null) {
                onEdit!();
              } else if (value == 'delete' && onDelete != null) {
                onDelete!();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Review'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Review', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  //============================================================================
  // TIMESTAMP ROW
  //============================================================================

  Widget _buildTimestampRow(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Icon(
          CupertinoIcons.clock,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          timeago.format(review.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (review.isEdited) ...[
          const SizedBox(width: 8),
          Text(
            '(edited)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  //============================================================================
  // OWNER REPLY
  //============================================================================

  Widget _buildOwnerReply(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.store_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Response from Owner',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isOwner && onDeleteReply != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
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
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
          if (review.ownerRepliedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              timeago.format(review.ownerRepliedAt!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  //============================================================================
  // ACTION BUTTONS
  //============================================================================

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    // Owner can reply if they haven't yet
    if (isOwner && !review.hasOwnerReply && onReply != null) {
      return TextButton.icon(
        onPressed: onReply,
        icon: const Icon(Icons.reply_rounded, size: 18),
        label: const Text('Reply'),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}