import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
import 'package:pendeza/shared/widgets/theme_mode_button.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/app_router.dart';
import '../../../0_auth/presentation/bloc/auth_bloc.dart';
import '../../../0_auth/presentation/bloc/auth_state.dart';

/// Profile tab for guests.
///
/// Reads the auth state and renders [GuestProfileView]. Navigation is the same
/// as before the redesign: login / sign up / favourites are all pushed.
class GuestProfileScreen extends StatelessWidget {
  const GuestProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! GuestMode) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return GuestProfileView(
          onLogin: () => context.push(AppRoutes.login),
          onSignUp: () => context.push(AppRoutes.signup),
          onFavorites: () => context.push(AppRoutes.clientFavorites),
          themeAction: const ThemeModeButton(onDark: true, size: 42),
        );
      },
    );
  }
}

/// Pure presentation of the guest profile (no blocs, no router).
class GuestProfileView extends StatelessWidget {
  final VoidCallback? onLogin;
  final VoidCallback? onSignUp;
  final VoidCallback? onFavorites;

  /// Small round button pinned to the hero's corner (the theme switch).
  final Widget? themeAction;

  const GuestProfileView({
    super.key,
    this.onLogin,
    this.onSignUp,
    this.onFavorites,
    this.themeAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientTheme.background(context),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(context),
              const SizedBox(height: 24),

              // Saved salons – the one thing guests can already use.
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
                child: Column(
                  children: [
                    _LinkCard(
                      icon: CupertinoIcons.heart_fill,
                      color: const Color(0xFFFF7A90),
                      title: 'client.profile.menu.favorites'.tr(),
                      subtitle: 'client.guest_profile.favorites_subtitle'.tr(),
                      onTap: onFavorites,
                    ),
                    // TEMPORARILY DISABLED - Payments turned off for App Store submission
                    if (AppConfig.paymentsEnabled) ...[
                      const SizedBox(height: 12),
                      _LinkCard(
                        icon: CupertinoIcons.creditcard_fill,
                        color: const Color(0xFF4DA3FF),
                        title: 'client.profile.menu.wallet'.tr(),
                        subtitle: 'client.guest_profile.wallet_subtitle'.tr(),
                        lockedLabel: 'client.guest_profile.wallet_locked'.tr(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _buildBenefits(context),
              const SizedBox(height: 28),

              _buildAvailableAsGuest(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── hero ───────────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context) {
    return ClientBrandHero(
      radius: 32,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Stack(
        children: [
          Column(
            children: [
          // Glass avatar with a soft halo.
          Container(
            width: 104,
            height: 104,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: const Icon(
                CupertinoIcons.person_fill,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'client.guest_profile.welcome'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -0.3,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'client.guest_profile.subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13.5,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 22),

          // Sign up (primary) …
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSignUp,
              icon: const Icon(CupertinoIcons.person_add_solid, size: 18),
              label: Text('client.guest_profile.create_account'.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                minimumSize: const Size(0, 52),
                elevation: 0,
                textStyle: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // … and log in (secondary).
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogin,
              icon: const Icon(CupertinoIcons.arrow_right_circle, size: 18),
              label: Text('auth.login.button'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                minimumSize: const Size(0, 52),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.55)),
                textStyle: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
            ],
          ),
          if (themeAction != null)
            Positioned(top: -12, right: -12, child: themeAction!),
        ],
      ),
    );
  }

  // ── benefits ───────────────────────────────────────────────────────────────

  Widget _buildBenefits(BuildContext context) {
    final benefits = [
      BenefitItem(
        icon: CupertinoIcons.calendar,
        title: 'client.guest_profile.benefit_book_title'.tr(),
        description: 'client.guest_profile.benefit_book_desc'.tr(),
      ),
      // TEMPORARILY DISABLED - Payments turned off for App Store submission
      if (AppConfig.paymentsEnabled)
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClientSectionHeader(title: 'client.guest_profile.why_create_account'.tr()),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
          child: ClientCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              children: [
                for (var i = 0; i < benefits.length; i++) ...[
                  if (i > 0) _divider(context),
                  _BenefitRow(
                    benefit: benefits[i],
                    color: ClientPalette.at(i),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── what guests can do ─────────────────────────────────────────────────────

  Widget _buildAvailableAsGuest(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClientSectionHeader(title: 'client.guest_profile.available_as_guest'.tr()),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
          child: ClientCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              children: [
                _GuestCapabilityRow(
                  icon: CupertinoIcons.search,
                  title: 'client.guest_profile.browse_salons'.tr(),
                  subtitle: 'client.guest_profile.browse_salons_desc'.tr(),
                ),
                _divider(context),
                _GuestCapabilityRow(
                  icon: CupertinoIcons.info_circle,
                  title: 'client.guest_profile.view_details'.tr(),
                  subtitle: 'client.guest_profile.view_details_desc'.tr(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: ClientTheme.border(context).withValues(alpha: 0.6),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// PIECES
// ═════════════════════════════════════════════════════════════════════════════

/// Tappable (or locked) shortcut row.
class _LinkCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  /// When set, the card is shown as locked with this label.
  final String? lockedLabel;

  const _LinkCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.lockedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final locked = lockedLabel != null;
    return Opacity(
      opacity: locked ? 0.7 : 1,
      child: ClientCard(
        onTap: locked ? null : onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClientIconTile(icon: icon, color: color, size: 46, solid: !locked),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ClientTheme.heading(context)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: ClientTheme.caption(context)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (locked)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.lock_fill,
                    size: 14,
                    color: ClientTheme.textSecondary(context),
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 92),
                    child: Text(
                      lockedLabel!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTheme.caption(context)
                          .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              )
            else
              Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: ClientTheme.textSecondary(context),
              ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final BenefitItem benefit;
  final Color color;

  const _BenefitRow({required this.benefit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClientIconTile(icon: benefit.icon, color: color, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(benefit.title, style: ClientTheme.heading(context)),
                const SizedBox(height: 2),
                Text(benefit.description, style: ClientTheme.caption(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestCapabilityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _GuestCapabilityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          ClientIconTile(
            icon: icon,
            color: Theme.of(context).colorScheme.primary,
            size: 42,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ClientTheme.heading(context)),
                const SizedBox(height: 2),
                Text(subtitle, style: ClientTheme.caption(context)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            CupertinoIcons.checkmark_circle_fill,
            size: 20,
            color: Color(0xFF00B894),
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
