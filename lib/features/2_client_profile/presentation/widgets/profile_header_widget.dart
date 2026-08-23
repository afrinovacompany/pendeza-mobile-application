import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
  final VoidCallback? onBookingsTap;
  final VoidCallback? onSavedTap;

  const ProfileHeaderWidget({
    super.key,
    required this.user,
    required this.stats,
    this.isImageUploading = false,
    required this.onAvatarTap,
    this.onBookingsTap,
    this.onSavedTap,
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
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
                    color: theme.colorScheme.scrim.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.onPrimary,
                    ),
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
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.camera_fill,
                    size: 16,
                    color: theme.colorScheme.onPrimary,
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (user.phoneNumber?.isNotEmpty == true) ...[
              const SizedBox(width: 8),
              Icon(Icons.verified, size: 14, color: theme.colorScheme.primary),
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
                  color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ProfileStatItem(
                  label: 'client.profile.stats.bookings'.tr(),
                  value: '${stats.totalBookings}',
                  onTap: onBookingsTap,
                ),
                _buildDivider(theme),
                ProfileStatItem(
                  label: 'client.profile.stats.reviews'.tr(),
                  value: '${stats.totalReviews}',
                ),
                _buildDivider(theme),
                ProfileStatItem(
                  label: 'client.profile.stats.saved'.tr(),
                  value: '${stats.totalFavorites}',
                  onTap: onSavedTap,
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
      color: theme.dividerColor.withValues(alpha: 0.5),
    );
  }
}
