import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/config/theme/app_constants.dart';
import '../../../0_auth/presentation/bloc/auth_bloc.dart';
import '../../../0_auth/presentation/bloc/auth_event.dart';
import '../../../0_auth/presentation/bloc/auth_state.dart';
import '../widgets/role_card.dart'; // Import the new RoleCard widget

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          // Use scaffold background color for consistency
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.padL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Text
                      // Key: "auth.role.title"
                      Text(
                        'auth.role.title'.tr(),
                        textAlign: TextAlign.center,
                        // Use consistent headline style
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.padS),
                      // Key: "auth.role.subtitle"
                      Text(
                        'auth.role.subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          // Consistent secondary text color
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: AppConstants.padXXL),

                      // "I'm a Client" Card - Using the new RoleCard widget
                      RoleCard(
                        icon: CupertinoIcons.person_2_fill, // Use filled icon
                        // Key: "auth.role.client_title"
                        title: 'auth.role.client_title'.tr(),
                        // Key: "auth.role.client_desc"
                        subtitle: 'auth.role.client_desc'.tr(),
                        onTap: isLoading
                            ? null
                            : () {
                          context
                              .read<AuthBloc>()
                              .add(const UpdateUserRoleRequested('client'));
                        },
                      ),
                      const SizedBox(height: AppConstants.padL),

                      // "I'm a Salon Owner" Card - Using the new RoleCard widget
                      RoleCard(
                        icon: CupertinoIcons.building_2_fill,
                        // Key: "auth.role.owner_title"
                        title: 'auth.role.owner_title'.tr(),
                        // Key: "auth.role.owner_desc"
                        subtitle: 'auth.role.owner_desc'.tr(),
                        onTap: isLoading
                            ? null
                            : () {
                          context
                              .read<AuthBloc>()
                              .add(const UpdateUserRoleRequested('owner'));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Loading Overlay
              if (isLoading)
                Container(
                  // Use scaffold background with opacity for overlay
                  color: theme.scaffoldBackgroundColor.withOpacity(0.7),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

// _buildRoleCard method removed as it's now in RoleCard widget
}