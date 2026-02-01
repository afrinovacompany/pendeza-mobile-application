import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
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
  State<_AuthenticatedProfileView> createState() => _AuthenticatedProfileViewState();
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
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null && context.mounted) {
      context.read<ProfileBloc>().add(UpdateProfileImage(
        userId: userId,
        imageFile: File(image.path),
      ));
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
          CustomSnackBar.show(context, message: state.message, type: SnackBarType.success);
        } else if (state is ProfileError) {
          CustomSnackBar.show(context, message: state.message, type: SnackBarType.error);
        }
      },
      builder: (context, profileState) {
        // Calculate stats safely
        final stats = (profileState is ProfileLoaded)
            ? profileState.stats
            : (profileState is ProfileImageUploading)
            ? profileState.previousStats ?? const ProfileStats()
            : const ProfileStats();

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<ProfileBloc>().add(LoadProfile(userId: user.uid, forceRefresh: true));
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
                      // 🆕 WALLET SECTION
                      _buildSectionHeader(context, 'Wallet'),
                      BlocBuilder<WalletBloc, WalletState>(
                        builder: (context, walletState) {
                          String balance = "TZS 0";
                          String subtitle = "Loading...";

                          if (walletState is WalletLoaded) {
                            balance = "TZS ${walletState.wallet.balance.toStringAsFixed(0)}";
                            subtitle = "Balance: $balance";
                          } else if (walletState is WalletError) {
                            subtitle = "Unable to load balance";
                          } else if (walletState is WalletLoading) {
                            subtitle = "Loading...";
                          }

                          return ProfileSectionCard(
                            children: [
                              ProfileMenuTile(
                                icon: CupertinoIcons.creditcard_fill,
                                iconColor: Colors.blueAccent,
                                title: 'My Wallet',
                                subtitle: subtitle,
                                onTap: () => context.push(AppRoutes.clientWallet),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: AppConstants.padL),

                      _buildSectionHeader(context, 'Account'),
                      ProfileSectionCard(
                        children: [
                          ProfileMenuTile(
                            icon: CupertinoIcons.person_crop_circle_fill,
                            title: 'Edit Profile',
                            subtitle: 'Name, Phone, and Gender',
                            onTap: () => context.push(AppRoutes.editProfile),
                          ),
                          ProfileMenuTile(
                            icon: CupertinoIcons.heart_fill,
                            title: 'My Favorites',
                            onTap: () => context.push(AppRoutes.clientFavorites),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.padL),

                      _buildSectionHeader(context, 'Preferences'),
                      ProfileSectionCard(
                        children: [
                          ProfileMenuTile(
                            icon: CupertinoIcons.globe,
                            title: 'Language',
                            trailing: Text(
                              context.locale.languageCode == 'sw' ? 'Kiswahili' : 'English',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                            ),
                            onTap: () => _showLanguagePicker(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.padXL),

                      ProfileSectionCard(
                        children: [
                          ProfileMenuTile(
                            icon: CupertinoIcons.square_arrow_right,
                            title: 'Log Out',
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
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showAdaptiveActionSheet<String>(
      context: context,
      title: 'Select Language',
      actions: [
        AdaptiveSheetAction(
          label: 'English',
          value: 'en',
          onPressed: () => context.setLocale(const Locale('en')),
        ),
        AdaptiveSheetAction(
          label: 'Kiswahili',
          value: 'sw',
          onPressed: () => context.setLocale(const Locale('sw')),
        ),
      ],
      cancelAction: const AdaptiveSheetAction(
        label: 'Cancel',
        isDefault: true,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context: context,
      title: 'Log Out',
      content: 'Are you sure you want to log out?',
      confirmText: 'Log Out',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      context.read<AuthBloc>().add(SignOutRequested());
    }
  }
}