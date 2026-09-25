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
import 'package:pendeza/features/2_client_notifications/presentation/bloc/notification_bloc.dart';
import 'package:pendeza/features/2_client_notifications/presentation/bloc/notification_state.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';
import 'package:pendeza/shared/widgets/theme_mode_button.dart';

/// Reads auth + notification state and renders [DashboardHeaderView].
///
/// Navigation is unchanged from before the redesign: bell → notifications
/// (push), avatar → profile (go), log in → login (push).
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String name = 'Guest';
        String? imageUrl;
        bool isAuthenticated = false;

        if (state is Authenticated) {
          name = state.user.fullName.split(' ').first;
          imageUrl = state.user.profilePictureUrl;
          isAuthenticated = true;
        }

        Widget view(int unread) => DashboardHeaderView(
              name: name,
              imageUrl: imageUrl,
              isAuthenticated: isAuthenticated,
              unreadCount: unread,
              onNotifications: () =>
                  context.push(AppRoutes.clientNotifications),
              onProfile: () => context.go(AppRoutes.clientProfile),
              onLogin: () => context.push(AppRoutes.login),
              onSearch: () => context.go(AppRoutes.clientDiscover),
              extraAction: const ThemeModeButton(onDark: true, size: 44),
            );

        if (!isAuthenticated) return view(0);

        return BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, notificationState) => view(
            notificationState is NotificationLoaded
                ? notificationState.unreadCount
                : 0,
          ),
        );
      },
    );
  }
}

/// Pure presentation of the dashboard header (no blocs, no router).
class DashboardHeaderView extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool isAuthenticated;
  final int unreadCount;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;
  final VoidCallback? onLogin;
  final VoidCallback? onSearch;

  /// Optional round action shown before the bell / login button
  /// (the app passes the theme switch).
  final Widget? extraAction;

  const DashboardHeaderView({
    super.key,
    required this.name,
    required this.isAuthenticated,
    this.imageUrl,
    this.unreadCount = 0,
    this.onNotifications,
    this.onProfile,
    this.onLogin,
    this.onSearch,
    this.extraAction,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'client.dashboard.greeting.morning'.tr();
    if (hour < 17) return 'client.dashboard.greeting.afternoon'.tr();
    return 'client.dashboard.greeting.evening'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return ClientBrandHero(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting().toUpperCase(),
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // One text run (name + wave) so a long name or a wide
                    // "Sign in" pill ellipsizes instead of overflowing.
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: name),
                          const TextSpan(
                            text: '  👋',
                            style: TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.4,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (extraAction != null) ...[
                extraAction!,
                const SizedBox(width: 8),
              ],
              if (isAuthenticated) ...[
                GlassCircleButton(
                  icon: CupertinoIcons.bell,
                  badgeCount: unreadCount,
                  size: 44,
                  onTap: onNotifications,
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onProfile,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85),
                        width: 2,
                      ),
                    ),
                    child: ProfileAvatar(
                      radius: 21,
                      imageUrl: imageUrl,
                      fullName: name,
                    ),
                  ),
                ),
              ] else
                _LoginPill(onTap: onLogin),
            ],
          ),
          const SizedBox(height: 18),
          _SearchPill(onTap: onSearch),
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  final VoidCallback? onTap;
  const _SearchPill({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.search,
                size: 20,
                color: Color(0xFF636E72),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'client.dashboard.search_hint'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF636E72),
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  CupertinoIcons.slider_horizontal_3,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginPill extends StatelessWidget {
  final VoidCallback? onTap;
  const _LoginPill({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.arrow_right_circle_fill,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'auth.login.button'.tr(),
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
