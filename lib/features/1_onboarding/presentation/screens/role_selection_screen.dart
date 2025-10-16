import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// --- Adjust these import paths to match your project structure ---
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/custom_card.dart';





import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../0_auth/presentation/bloc/auth_bloc.dart';
import '../../../0_auth/presentation/bloc/auth_event.dart';
import '../../../0_auth/presentation/bloc/auth_state.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Show a loading indicator in the center of the screen
        // when the role is being updated.
        final isLoading = state is AuthLoading;

        return Scaffold(
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.padL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Header Text ---
                      Text(
                        'How will you use the app?',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayMedium,
                      ),
                      const SizedBox(height: AppConstants.padS),
                      Text(
                        'Choose your role to get a personalized experience.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(178),
                        ),
                      ),
                      const SizedBox(height: AppConstants.padXXL),

                      // --- "I'm a Client" Card ---
                      _buildRoleCard(
                        context: context,
                        icon: CupertinoIcons.person_2,
                        title: 'I\'m a Client',
                        subtitle: 'Find and book salon services near you.',
                        // Dispatch the event with the 'client' role.
                        // Disable the button while loading.
                        onTap: isLoading ? null : () {
                          context
                              .read<AuthBloc>()
                              .add(const UpdateUserRoleRequested('client'));
                        },
                      ),
                      const SizedBox(height: AppConstants.padL),

                      // --- "I'm a Salon Owner" Card ---
                      _buildRoleCard(
                        context: context,
                        icon: CupertinoIcons.building_2_fill,
                        title: 'I\'m a Salon Owner',
                        subtitle: 'Manage your business and appointments.',
                        // Dispatch the event with the 'owner' role.
                        // Disable the button while loading.
                        onTap: isLoading ? null : () {
                          context
                              .read<AuthBloc>()
                              .add(const UpdateUserRoleRequested('owner'));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // --- Loading Overlay ---
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// A helper widget to build a consistent card for role selection.
  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return CustomCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padM),
        child: Row(
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(width: AppConstants.padL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppConstants.padXXS),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(178),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

