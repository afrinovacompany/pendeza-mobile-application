import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_router.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../0_auth/presentation/bloc/auth_bloc.dart';
import '../../../0_auth/presentation/bloc/auth_state.dart';


/// Profile screen for guest users.
class GuestProfileScreen extends StatelessWidget {
  const GuestProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! GuestMode) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          // NEW: AppBar added to show Login button in the action area (where logout usually is)
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('client.guest_profile.title'.tr()),
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: TextButton.icon(
                  onPressed: () => context.push(AppRoutes.login),
                  icon: const Icon(Icons.login_rounded),
                  label: Text('auth.login.button'.tr()),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.padL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppConstants.padS),

                  // Guest Avatar
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.2),
                            theme.colorScheme.primary.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.person_circle,
                        size: 80,
                        color: theme.colorScheme.primary.withOpacity(0.6),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.padL),

                  // Welcome Text
                  Text(
                    'client.guest_profile.welcome'.tr(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppConstants.padS),

                  Text(
                    'client.guest_profile.subtitle'.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppConstants.padL),

                  // Guest Features
                  _buildGuestFeatureCard(
                    theme,
                    icon: CupertinoIcons.heart_fill,
                    iconColor: Colors.red,
                    title: 'client.profile.menu.favorites'.tr(),
                    subtitle: 'client.guest_profile.favorites_subtitle'.tr(),
                    onTap: () => context.push(AppRoutes.clientFavorites),
                  ),

                  const SizedBox(height: AppConstants.padM),

                  // 🆕 WALLET PREVIEW FOR GUESTS (Shows locked state)
                  _buildLockedFeatureCard(
                    theme,
                    icon: CupertinoIcons.creditcard_fill,
                    iconColor: Colors.blueAccent,
                    title: 'client.profile.menu.wallet'.tr(),
                    subtitle: 'client.guest_profile.wallet_subtitle'.tr(),
                    lockedMessage: 'client.guest_profile.wallet_locked'.tr(),
                  ),

                  const SizedBox(height: AppConstants.padXL),

                  // Benefits Card
                  _buildBenefitsCard(theme),

                  const SizedBox(height: AppConstants.padXL),

                  // Sign Up Button
                  ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.signup),
                    icon: const Icon(Icons.person_add_rounded, size: 20),
                    label: Text('client.guest_profile.create_account'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.padM + 4,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppConstants.radiusM,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.padM),

                  // Sign In Button
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.login),
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: Text('auth.login.button'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.padM + 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppConstants.radiusM,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.padXXL),

                  // Guest Features Section
                  _buildGuestFeaturesSection(theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuestFeatureCard(
      ThemeData theme, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppConstants.radiusM,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(CupertinoIcons.chevron_forward),
      ),
    );
  }

  // 🆕 NEW: Locked feature card for guests
  Widget _buildLockedFeatureCard(
      ThemeData theme, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String subtitle,
        required String lockedMessage,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: AppConstants.radiusM,
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        enabled: false,
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor.withOpacity(0.4)),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.lock_fill,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            lockedMessage,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsCard(ThemeData theme) {
    final benefits = [
      BenefitItem(
        icon: CupertinoIcons.calendar,
        title: 'client.guest_profile.benefit_book_title'.tr(),
        description: 'client.guest_profile.benefit_book_desc'.tr(),
      ),
      BenefitItem(
        icon: CupertinoIcons.creditcard,
        title: 'client.guest_profile.benefit_wallet_title'.tr(),
        description: 'client.guest_profile.benefit_wallet_desc'.tr(),
      ),
      BenefitItem(
        icon: CupertinoIcons.heart,
        title: 'client.guest_profile.benefit_favorites_title'.tr(),
        description: 'client.guest_profile.benefit_favorites_desc'.tr(),
      ),
      BenefitItem(
        icon: CupertinoIcons.bell,
        title: 'client.guest_profile.benefit_notifications_title'.tr(),
        description: 'client.guest_profile.benefit_notifications_desc'.tr(),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.primary.withOpacity(0.03),
          ],
        ),
        borderRadius: AppConstants.radiusL,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.sparkles,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: AppConstants.padS),
              Text(
                'client.guest_profile.why_create_account'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.padL),
          ...benefits.map((benefit) => _buildBenefitRow(theme, benefit)),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(ThemeData theme, BenefitItem benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.padM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.padS),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: AppConstants.radiusS,
            ),
            child: Icon(
              benefit.icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  benefit.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestFeaturesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'client.guest_profile.available_as_guest'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.padM),

        _buildFeatureTile(
          theme,
          icon: CupertinoIcons.search,
          title: 'client.guest_profile.browse_salons'.tr(),
          subtitle: 'client.guest_profile.browse_salons_desc'.tr(),
        ),

        _buildFeatureTile(
          theme,
          icon: CupertinoIcons.info_circle,
          title: 'client.guest_profile.view_details'.tr(),
          subtitle: 'client.guest_profile.view_details_desc'.tr(),
        ),
      ],
    );
  }

  Widget _buildFeatureTile(
      ThemeData theme, {
        required IconData icon,
        required String title,
        required String subtitle,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.padM),
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppConstants.radiusM,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary.withOpacity(0.6),
            size: 24,
          ),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.checkmark_circle_fill,
            color: theme.colorScheme.primary.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class BenefitItem {
  final IconData icon;
  final String title;
  final String description;

  BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}