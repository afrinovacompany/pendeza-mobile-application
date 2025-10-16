import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- Adjust these import paths to match your project structure ---\
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/profile_avatar.dart';
import '../../../../shared/widgets/secondary_button.dart';

import '../../../0_auth/presentation/bloc/auth_bloc.dart';
import '../../../0_auth/presentation/bloc/auth_event.dart';
import '../../../0_auth/presentation/bloc/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- INTEGRATION: Watch AuthBloc state ---
    final authState = context.watch<AuthBloc>().state;
    String fullName = 'Guest';
    String email = '';
    String? imageUrl;
    bool isLoading = authState is AuthLoading;

    if (authState is Authenticated) {
      fullName = authState.user.fullName;
      email = authState.user.email;
      imageUrl = authState.user.profilePictureUrl;
    }
    // ------------------------------------------

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
                  color: theme.colorScheme.onSurface.withAlpha(178),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.padXL),

          // --- Menu List Section ---
          _buildProfileMenuItem(
            context,
            icon: CupertinoIcons.person_circle,
            title: 'Edit Profile',
            onTap: isLoading ? null : () {
              // TODO: Navigate to Edit Profile Screen
            },
          ),
          _buildProfileMenuItem(
            context,
            icon: CupertinoIcons.bell,
            title: 'Notifications',
            onTap: isLoading ? null : () {
              // TODO: Navigate to Notifications Screen
            },
          ),
          _buildProfileMenuItem(
            context,
            icon: CupertinoIcons.creditcard,
            title: 'Payment Methods',
            onTap: isLoading ? null : () {
              // TODO: Navigate to Payment Methods Screen
            },
          ),
          _buildProfileMenuItem(
            context,
            icon: CupertinoIcons.shield,
            title: 'Security',
            onTap: isLoading ? null : () {
              // TODO: Navigate to Security Screen
            },
          ),
          const Divider(height: AppConstants.padXL),
          _buildProfileMenuItem(
            context,
            icon: CupertinoIcons.question_circle,
            title: 'Help & Support',
            onTap: isLoading ? null : () {
              // TODO: Navigate to Help & Support Screen
            },
          ),
          const SizedBox(height: AppConstants.padXL),

          // --- Logout Button ---
          SecondaryButton(
            text: 'LOG OUT',
            onPressed: isLoading ? null : () {
              // --- INTEGRATION: Dispatch SignOutRequested event ---
              context.read<AuthBloc>().add(SignOutRequested());
              // The AuthBloc will handle the sign out and the router will redirect to /login
              // ---------------------------------------------------
            },
            iconData: CupertinoIcons.square_arrow_left,
          ),
        ],
      ),
    );
  }

  /// A helper method to build a consistent list tile for profile menu items.
  Widget _buildProfileMenuItem(BuildContext context,
      {required IconData icon, required String title, required VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: theme.colorScheme.primary, size: 28),
      title: Text(title, style: theme.textTheme.titleMedium),
      trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
      contentPadding: const EdgeInsets.symmetric(vertical: AppConstants.padXS),
    );
  }
}
