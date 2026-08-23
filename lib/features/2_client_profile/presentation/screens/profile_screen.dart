import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:pendeza/app/config/app_config.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/widgets/adaptive/adaptive_dialog.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_event.dart'; // For SignOut
import 'package:pendeza/features/2_client_profile/presentation/bloc/profile_bloc.dart';
import 'package:pendeza/features/2_client_profile/presentation/bloc/profile_event.dart';
import 'package:pendeza/features/2_client_profile/presentation/bloc/profile_state.dart';
import 'package:pendeza/features/2_client_profile/presentation/screens/profile_section_card.dart';
import 'package:pendeza/features/2_client_profile/presentation/widgets/profile_header_widget.dart';
import 'package:pendeza/features/2_client_profile/presentation/widgets/profile_menu_tile.dart';
import 'package:pendeza/shared/widgets/custom_snackbar.dart';

// Wallet imports
import 'package:pendeza/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_event.dart';

// Import the Guest Screen directly
import '../../data/models/profile_stats.dart';
import 'guest_profile_screen.dart';

/// ============================================================================
/// CLIENT PROFILE SCREEN - FIXED VERSION
/// ============================================================================
///
/// KEY FIX: We now USE the globally provided WalletBloc and ProfileBloc from
/// app.dart instead of creating new local instances.
///
/// PROBLEM BEFORE:
/// - WalletBloc was registered as a SINGLETON in service_locator.dart
/// - app.dart provided it globally via BlocProvider.value(value: sl<WalletBloc>())
/// - This screen ALSO created a local BlocProvider that called sl<WalletBloc>()
/// - Since it's a singleton, both providers pointed to the SAME instance
/// - When navigating away, the local BlocProvider disposed and CLOSED the bloc
/// - On returning, the bloc was already closed → "Cannot add new events after calling close"
///
/// SOLUTION:
/// - Don't create new BlocProviders here - just READ the existing ones from context
/// - Load data by adding events to the existing blocs
/// - The blocs stay alive for the entire app lifecycle
/// ============================================================================

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. WATCH AUTH STATE
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // --- CASE A: GUEST USER ---
        if (authState is GuestMode) {
          return const GuestProfileScreen();
        }

        // --- CASE B: AUTHENTICATED USER ---
        if (authState is Authenticated) {
          // ✅ FIX: Use the EXISTING global blocs instead of creating new ones
          // Just trigger data loading when screen opens
          return _AuthenticatedProfileView(userId: authState.user.uid);
        }

        // --- CASE C: LOADING / UNKNOWN ---
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

/// The Full Profile UI - Only shown when authenticated.
///
/// ✅ FIXED: Now a StatefulWidget so we can trigger data loading in initState
/// instead of creating new BlocProviders
class _AuthenticatedProfileView extends StatefulWidget {
  final String userId;

  const _AuthenticatedProfileView({required this.userId});

  @override
  State<_AuthenticatedProfileView> createState() =>
      _AuthenticatedProfileViewState();
}

class _AuthenticatedProfileViewState extends State<_AuthenticatedProfileView> {
  @override
  void initState() {
    super.initState();
    // ✅ FIX: Load data using the EXISTING global blocs
    // Use addPostFrameCallback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  void _loadProfileData() {
    // Load profile stats using the existing ProfileBloc
    context.read<ProfileBloc>().add(LoadProfile(userId: widget.userId));

    // Load wallet using the existing WalletBloc
    context.read<WalletBloc>().add(LoadWallet(widget.userId));
  }

  Future<void> _pickAndUploadImage(BuildContext context, String userId) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null && context.mounted) {
      context.read<ProfileBloc>().add(
        UpdateProfileImage(userId: userId, imageFile: File(image.path)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.read<AuthBloc>().state as Authenticated;
    final user = authState.user;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          CustomSnackBar.show(
            context,
            message: state.message,
            type: SnackBarType.success,
          );
        } else if (state is ProfileError) {
          CustomSnackBar.show(
            context,
            message: state.message,
            type: SnackBarType.error,
          );
        }
      },
      builder: (context, profileState) {
        // Calculate stats safely
        final stats =
            (profileState is ProfileLoaded)
                ? profileState.stats
                : (profileState is ProfileImageUploading)
                ? profileState.previousStats ?? const ProfileStats()
                : const ProfileStats();

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<ProfileBloc>().add(
                  LoadProfile(userId: user.uid, forceRefresh: true),
                );
                context.read<WalletBloc>().add(RefreshWallet(user.uid));
              },
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: ProfileHeaderWidget(
                      user: user,
                      stats: stats,
                      isImageUploading: profileState is ProfileImageUploading,
                      onAvatarTap: () => _pickAndUploadImage(context, user.uid),
                      onBookingsTap: () => context.go(AppRoutes.clientBookings),
                      onSavedTap: () => context.push(AppRoutes.clientFavorites),
                    ),
                  ),

                  // Grouped Menu Sections
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.padL,
                      vertical: AppConstants.padL,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // TEMPORARILY DISABLED - Payments turned off for App Store submission
                        if (AppConfig.paymentsEnabled) ...[
                          _buildSectionHeader(
                            context,
                            'client.profile.section_wallet'.tr(),
                          ),
                          BlocBuilder<WalletBloc, WalletState>(
                            builder: (context, walletState) {
                              String subtitle = 'common.loading'.tr();

                              if (walletState is WalletLoaded) {
                                final balance =
                                    "TZS ${walletState.wallet.balance.toStringAsFixed(0)}";
                                subtitle = 'client.profile.wallet_balance'.tr(
                                  args: [balance],
                                );
                              } else if (walletState is WalletError) {
                                subtitle = 'client.profile.wallet_error'.tr();
                              }

                              return ProfileSectionCard(
                                children: [
                                  ProfileMenuTile(
                                    icon: CupertinoIcons.creditcard_fill,
                                    title: 'client.profile.menu.wallet'.tr(),
                                    subtitle: subtitle,
                                    onTap:
                                        () => context.push(
                                          AppRoutes.clientWallet,
                                        ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: AppConstants.padL),
                        ],

                        _buildSectionHeader(
                          context,
                          'client.profile.section_account'.tr(),
                        ),
                        ProfileSectionCard(
                          children: [
                            ProfileMenuTile(
                              icon: CupertinoIcons.person_crop_circle_fill,
                              title: 'client.profile.menu.edit_profile'.tr(),
                              subtitle:
                                  'client.profile.edit_profile_subtitle'.tr(),
                              onTap: () => context.push(AppRoutes.editProfile),
                            ),
                            ProfileMenuTile(
                              icon: CupertinoIcons.heart_fill,
                              title: 'client.profile.menu.favorites'.tr(),
                              onTap:
                                  () => context.push(AppRoutes.clientFavorites),
                            ),
                            ProfileMenuTile(
                              icon: CupertinoIcons.bell_fill,
                              title: 'client.profile.menu.notifications'.tr(),
                              onTap:
                                  () => context.push(
                                    AppRoutes.clientNotifications,
                                  ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppConstants.padL),

                        _buildSectionHeader(
                          context,
                          'client.profile.section_preferences'.tr(),
                        ),
                        ProfileSectionCard(
                          children: [
                            ProfileMenuTile(
                              icon: CupertinoIcons.globe,
                              title: 'client.profile.menu.language'.tr(),
                              trailing: Text(
                                context.locale.languageCode == 'sw'
                                    ? 'client.profile.language_selector.swahili'
                                        .tr()
                                    : 'client.profile.language_selector.english'
                                        .tr(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              onTap: () => _showLanguagePicker(context),
                            ),
                            ProfileMenuTile(
                              icon: CupertinoIcons.question_circle_fill,
                              title: 'client.profile.menu.help'.tr(),
                              onTap: () {
                                context.push(
                                  Uri(
                                    path: '/help-support',
                                    queryParameters: {'showFAQ': 'false'},
                                  ).toString(),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: AppConstants.padXL),

                        ProfileSectionCard(
                          children: [
                            ProfileMenuTile(
                              icon: CupertinoIcons.square_arrow_right,
                              title: 'client.profile.menu.logout'.tr(),
                              isDestructive: true,
                              showChevron: false,
                              onTap: () => _showLogoutDialog(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.padXL * 2),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showAdaptiveActionSheet<String>(
      context: context,
      title: 'client.profile.language_selector.title'.tr(),
      actions: [
        AdaptiveSheetAction(
          label: 'client.profile.language_selector.english'.tr(),
          value: 'en',
          onPressed: () => context.setLocale(const Locale('en')),
        ),
        AdaptiveSheetAction(
          label: 'client.profile.language_selector.swahili'.tr(),
          value: 'sw',
          onPressed: () => context.setLocale(const Locale('sw')),
        ),
      ],
      cancelAction: AdaptiveSheetAction(
        label: 'common.cancel'.tr(),
        isDefault: true,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context: context,
      title: 'client.profile.logout_title'.tr(),
      content: 'client.profile.logout_confirm'.tr(),
      confirmText: 'client.profile.menu.logout'.tr(),
      cancelText: 'common.cancel'.tr(),
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      context.read<AuthBloc>().add(SignOutRequested());
    }
  }
}
