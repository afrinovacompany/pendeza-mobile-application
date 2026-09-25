import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';

import '../../data/models/profile_stats.dart';
import 'profile_stats_item.dart';

/// Brand hero for the signed-in profile: avatar, identity and key stats.
class ProfileHeaderWidget extends StatelessWidget {
  final UserModel user;
  final ProfileStats stats;
  final bool isImageUploading;
  final VoidCallback onAvatarTap;
  final VoidCallback? onBookingsTap;
  final VoidCallback? onSavedTap;

  /// Small round button pinned to the hero's corner (the theme switch).
  final Widget? themeAction;

  const ProfileHeaderWidget({
    super.key,
    required this.user,
    required this.stats,
    this.isImageUploading = false,
    required this.onAvatarTap,
    this.onBookingsTap,
    this.onSavedTap,
    this.themeAction,
  });

  @override
  Widget build(BuildContext context) {
    final hasVerifiedPhone = user.phoneNumber?.isNotEmpty == true;

    return ClientBrandHero(
      radius: 32,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
      child: Stack(
        children: [
          Column(
            children: [
          // 1. AVATAR WITH EDIT BADGE
          Stack(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
                  child: ProfileAvatar(
                    imageUrl: user.profilePictureUrl,
                    radius: 50,
                    fullName: user.fullName,
                  ),
                ),
              ),
              if (isImageUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.camera_fill,
                      size: 15,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. NAME & IDENTITY
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.3,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              if (hasVerifiedPhone) ...[
                const SizedBox(width: 6),
                const Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 15,
                  color: Color(0xFF8FE3C9),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // 3. STATS
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: ProfileStatItem(
                      label: 'client.profile.stats.bookings'.tr(),
                      value: '${stats.totalBookings}',
                      onTap: onBookingsTap,
                    ),
                  ),
                  _divider(),
                  Expanded(
                    child: ProfileStatItem(
                      label: 'client.profile.stats.reviews'.tr(),
                      value: '${stats.totalReviews}',
                    ),
                  ),
                  _divider(),
                  Expanded(
                    child: ProfileStatItem(
                      label: 'client.profile.stats.saved'.tr(),
                      value: '${stats.totalFavorites}',
                      onTap: onSavedTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
          if (themeAction != null)
            Positioned(top: -10, right: -10, child: themeAction!),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: Colors.white.withValues(alpha: 0.25),
      );
}
