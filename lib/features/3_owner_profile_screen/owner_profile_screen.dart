import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/services/local_storage_service.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/2_client_profile/presentation/bloc/profile_bloc.dart';
import 'package:pendeza/features/3_owner_profile_screen/edit_owner_profile_screen.dart';
import 'package:pendeza/features/3_owner_profile_screen/help_support_screen.dart';
import 'package:pendeza/features/3_owner_profile_screen/notifications_settings_screen.dart';

import '../../app/config/theme/app_constants.dart';
import '../3_owner_management/presentation/owner_chrome.dart';
import '../../shared/widgets/profile_avatar.dart';
import '../../shared/widgets/secondary_button.dart';
import '../0_auth/presentation/bloc/auth_bloc.dart';
import '../0_auth/presentation/bloc/auth_event.dart';
import '../0_auth/presentation/bloc/auth_state.dart';

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Watch AuthBloc state for user info
    final authState = context.watch<AuthBloc>().state;
    String fullName = 'Salon Owner';
    String email = '';
    String? imageUrl;
    bool isLoading = authState is AuthLoading;

    if (authState is Authenticated) {
      fullName = authState.user.fullName;
      email = authState.user.email;
      imageUrl = authState.user.profilePictureUrl;
    }

    return Scaffold(
      appBar: ownerTabAppBar(
        context,
        title: 'client.profile.title'.tr(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.padL),
        children: [
          // --- User Info Section ---
          Column(
            children: [
              ProfileAvatar(
                radius: 50,
                fullName: fullName,
                imageUrl: imageUrl,
              ),
              const SizedBox(height: AppConstants.padM),
              Text(
                fullName,
                style: theme.textTheme.displaySmall,
              ),
              Text(
                email,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.padXL),

          // --- BUSINESS SECTION ---
          Text(
            'owner.profile.business_section'.tr(),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppConstants.padS),

          // FIX: Navigate to Salon Profile Screen
          _buildProfileMenuItem(
            context,
            icon: CupertinoIcons.building_2_fill,
            title: 'owner.profile.manage_salon'.tr(),
            subtitle: 'owner.profile.manage_salon_subtitle'.tr(),
            onTap: isLoading ? null : () {
              // Navigate to the salon profile management screen
              context.push('/owner/salon-profile');
            },
          ),
          const SizedBox(height: AppConstants.padXL),

          // --- ACCOUNT SECTION ---
          Text(
            'owner.profile.account_section'.tr(),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppConstants.padS),

          _buildProfileMenuItem(
            context,
            icon: CupertinoIcons.person_circle,
            title: 'client.profile.menu.edit_profile'.tr(),
            subtitle: 'owner.profile.edit_profile_subtitle'.tr(),
            onTap: isLoading ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: sl<ProfileBloc>(),
                    child: const EditOwnerProfileScreen(),
                  ),
                ),
              );
            },
          ),
          _buildProfileMenuItem(
            context,
            icon: CupertinoIcons.bell,
            title: 'client.profile.menu.notifications'.tr(),
            subtitle: 'owner.profile.notifications_subtitle'.tr(),
            onTap: isLoading ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsSettingsScreen(),
                ),
              );
            },
          ),

          // --- LANGUAGE SELECTOR (NEW for Owner too) ---
          _buildProfileMenuItem(
            context,
            icon: Icons.language,
            // Key: "client.profile.menu.language"
            title: 'client.profile.menu.language'.tr(),
            subtitle: context.locale.languageCode == 'sw' ? 'Kiswahili' : 'English',
            onTap: () => _showLanguageSelector(context),
          ),

          _buildProfileMenuItem(
            context,
            icon: CupertinoIcons.question_circle,
            title: 'client.profile.menu.help'.tr(),
            subtitle: 'owner.profile.help_subtitle'.tr(),
            onTap: isLoading ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: AppConstants.padXL),

          // --- Logout Button ---
          SecondaryButton(
            // Key: "client.profile.menu.logout"
            text: 'client.profile.menu.logout'.tr(),
            onPressed: isLoading
                ? null
                : () {
              context.read<AuthBloc>().add(SignOutRequested());
            },
            iconData: CupertinoIcons.square_arrow_left,
          ),
          const SizedBox(height: AppConstants.padL),
        ],
      ),
    );
  }

  /// Shows a bottom sheet to select language
  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  // Key: "client.profile.language_selector.title"
                  'client.profile.language_selector.title'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                // Key: "client.profile.language_selector.english"
                title: Text('client.profile.language_selector.english'.tr()),
                trailing: context.locale.languageCode == 'en'
                    ? const Icon(Icons.check_circle, color: Colors.blue)
                    : null,
                onTap: () async {
                  await context.setLocale(const Locale('en'));
                  await sl<LocalStorageService>().setLocale('en');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Text('🇹🇿', style: TextStyle(fontSize: 24)),
                // Key: "client.profile.language_selector.swahili"
                title: Text('client.profile.language_selector.swahili'.tr()),
                trailing: context.locale.languageCode == 'sw'
                    ? const Icon(Icons.check_circle, color: Colors.blue)
                    : null,
                onTap: () async {
                  await context.setLocale(const Locale('sw'));
                  await sl<LocalStorageService>().setLocale('sw');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback? onTap,
      }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: theme.colorScheme.primary, size: 28),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
      contentPadding: const EdgeInsets.symmetric(vertical: AppConstants.padS),
    );
  }
}