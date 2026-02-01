import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/config/app_router.dart';
import '../features/0_auth/presentation/bloc/auth_bloc.dart';
import '../features/0_auth/presentation/bloc/auth_state.dart';

/// The very first screen shown to the user.
///
/// NEW BEHAVIOR:
/// - Shows app logo and waits for AuthBloc to determine state
/// - If no auth state: navigates to CLIENT DASHBOARD (guest mode)
/// - If authenticated: navigates to appropriate dashboard
/// - Seamless experience - no forced auth wall!
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
    // Ensure splash screen shows for at least 1.5 seconds (shorter for better UX)
    _minimumDisplayTimer = Timer(const Duration(milliseconds: 1500), () {
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

    // NEW: Guest mode - go straight to client dashboard
    if (state is GuestMode) {
      context.go(AppRoutes.clientHome);
      return;
    }

    // Fully authenticated users
    if (state is Authenticated) {
      final userRole = state.user.role ?? 'client';
      context.go(userRole == 'owner' ? AppRoutes.ownerHome : AppRoutes.clientHome);
      return;
    }

    // Users who need to complete onboarding
    if (state is RoleSelectionRequired) {
      context.go(AppRoutes.roleSelection);
      return;
    }

    if (state is ClientProfileSetupRequired) {
      context.go(AppRoutes.clientSetup);
      return;
    }

    if (state is OwnerProfileSetupRequired) {
      context.go(AppRoutes.ownerSetup);
      return;
    }

    // NEW: Auth required - show auth screen with context
    if (state is AuthenticationRequired) {
      context.go(AppRoutes.login);
      return;
    }

    // Fallback - should rarely hit this with guest mode
    context.go(AppRoutes.clientHome);
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
                  color: Colors.white.withOpacity(0.9),
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