import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';

import 'package:pendeza/shared/widgets/profile_avatar.dart';
import '../../data/models/profile_stats.dart';
import 'profile_stats_item.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final UserModel user;
  final ProfileStats stats;
  final bool isImageUploading;
  final VoidCallback onAvatarTap;

  const ProfileHeaderWidget({
    super.key,
    required this.user,
    required this.stats,
    this.isImageUploading = false,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: AppConstants.padL),

        // 1. AVATAR WITH EDIT BADGE
        Stack(
          children: [
            GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 4,
                  ),
                ),
                child: ProfileAvatar(
                  imageUrl: user.profilePictureUrl,
                  radius: 60,
                  fullName: user.fullName,
                ),
              ),
            ),
            if (isImageUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    CupertinoIcons.camera_fill,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.padM),

        // 2. NAME & IDENTITY
        Text(
          user.fullName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (user.phoneNumber!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.verified,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),

        const SizedBox(height: AppConstants.padL),

        // 3. STATS ROW (The "Engagement" bar)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppConstants.padM),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusValL),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ProfileStatItem(
                  label: 'Bookings',
                  value: '${stats.totalBookings}',
                ),
                _buildDivider(theme),
                ProfileStatItem(
                  label: 'Reviews',
                  value: '${stats.totalReviews}',
                ),
                _buildDivider(theme),
                ProfileStatItem(
                  label: 'Saved',
                  value: '${stats.totalFavorites}',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      height: 30,
      width: 1,
      color: theme.dividerColor.withOpacity(0.5),
    );
  }
}