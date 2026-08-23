import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../app/config/app_router.dart';
import '../app/config/theme/app_constants.dart';
import '../features/0_auth/presentation/bloc/auth_bloc.dart';
import '../features/0_auth/presentation/bloc/auth_event.dart';
import '../features/0_auth/presentation/bloc/auth_state.dart';

/// The very first screen shown to the user.
///
/// - Shows app branding and waits for AuthBloc to determine state
/// - If no auth state: navigates to CLIENT DASHBOARD (guest mode)
/// - If authenticated: navigates to appropriate dashboard
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minimumDisplay = Duration(milliseconds: 1500);
  static const _safetyTimeout = Duration(seconds: 8);

  bool _hasNavigated = false;
  Timer? _minimumDisplayTimer;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    _minimumDisplayTimer = Timer(_minimumDisplay, _checkAndNavigate);
    _safetyTimer = Timer(_safetyTimeout, _onSafetyTimeout);
  }

  @override
  void dispose() {
    _minimumDisplayTimer?.cancel();
    _safetyTimer?.cancel();
    super.dispose();
  }

  void _checkAndNavigate() {
    if (_hasNavigated || !mounted) return;

    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthInitial && authState is! AuthLoading) {
      _hasNavigated = true;
      _safetyTimer?.cancel();
      _navigateBasedOnState(authState);
    }
  }

  /// If auth never leaves loading, don't keep the user on splash forever.
  void _onSafetyTimeout() {
    if (_hasNavigated || !mounted) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthInitial || authState is AuthLoading) {
      context.read<AuthBloc>().add(ContinueAsGuest());
      return;
    }

    _checkAndNavigate();
  }

  void _navigateBasedOnState(AuthState state) {
    if (!mounted) return;

    if (state is GuestMode) {
      context.go(AppRoutes.clientHome);
      return;
    }

    if (state is Authenticated) {
      final userRole = state.user.role ?? 'client';
      context.go(userRole == 'owner' ? AppRoutes.ownerHome : AppRoutes.clientHome);
      return;
    }

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

    if (state is AuthenticationRequired) {
      context.go(AppRoutes.login);
      return;
    }

    context.go(AppRoutes.clientHome);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (_minimumDisplayTimer?.isActive == false) {
          _checkAndNavigate();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    width: 128,
                    height: 128,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface,
                    ),
                    child: Image.asset(
                      'assets/images/icons/App_Icon.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.cut_sharp,
                          size: 72,
                          color: theme.colorScheme.primary,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.padL),
                Text(
                  'splash.app_name'.tr(),
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.padXS),
                Text(
                  'splash.tagline'.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 80),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
