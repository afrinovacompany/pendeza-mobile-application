import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/config/app_router.dart';
import '../features/0_auth/presentation/bloc/auth_bloc.dart';
import '../features/0_auth/presentation/bloc/auth_state.dart';

/// The very first screen shown to the user.
///
/// It displays the app logo and waits until the AuthBloc has determined the
/// initial authentication state, ensuring the app is fully ready before proceeding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;
  Timer? _minimumDisplayTimer;

  @override
  void initState() {
    super.initState();
    // Ensure splash screen shows for at least 2 seconds
    _minimumDisplayTimer = Timer(const Duration(seconds: 2), () {
      _checkAndNavigate();
    });
  }

  @override
  void dispose() {
    _minimumDisplayTimer?.cancel();
    super.dispose();
  }

  void _checkAndNavigate() {
    if (_hasNavigated || !mounted) return;

    final authState = context.read<AuthBloc>().state;

    // Only navigate if we're out of the initial loading state
    if (authState is! AuthInitial && authState is! AuthLoading) {
      _hasNavigated = true;
      _navigateBasedOnState(authState);
    }
  }

  void _navigateBasedOnState(AuthState state) {
    if (!mounted) return;

    if (state is Authenticated) {
      // User is fully authenticated, go to their dashboard
      final userRole = state.user.role ?? 'client';
      context.go(userRole == 'owner' ? AppRoutes.ownerHome : AppRoutes.clientHome);
    } else if (state is RoleSelectionRequired) {
      // User needs to select a role
      context.go(AppRoutes.roleSelection);
    } else if (state is ClientProfileSetupRequired) {
      // Client needs to complete profile
      context.go(AppRoutes.clientSetup);
    } else if (state is OwnerProfileSetupRequired) {
      // Owner needs to complete profile
      context.go(AppRoutes.ownerSetup);
    } else {
      // Unauthenticated or error - go to login
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // If we're past the minimum display time, navigate immediately
        if (_minimumDisplayTimer?.isActive == false) {
          _checkAndNavigate();
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Icon(
                Icons.cut_sharp,
                size: 120,
                color: Colors.white,
              ),
              const SizedBox(height: 24),

              // App Name
              Text(
                'Pendeza',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Style, Your Schedule',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 80),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}