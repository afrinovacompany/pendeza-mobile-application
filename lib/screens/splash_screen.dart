import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../app/config/app_router.dart';
import '../features/0_auth/presentation/bloc/auth_bloc.dart';
import '../features/0_auth/presentation/bloc/auth_event.dart';
import '../features/0_auth/presentation/bloc/auth_state.dart';
import 'splash_view.dart';

/// The very first screen shown to the user.
///
/// - Shows the animated wordmark ([SplashView]) and waits for AuthBloc
/// - If no auth state: navigates to CLIENT DASHBOARD (guest mode)
/// - If authenticated: navigates to appropriate dashboard
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Long enough for the intro animation to land before we move on.
  static const _minimumDisplay = Duration(milliseconds: 1900);
  static const _safetyTimeout = Duration(seconds: 8);
  static const _exitDuration = Duration(milliseconds: 350);

  bool _hasNavigated = false;
  Timer? _minimumDisplayTimer;
  Timer? _safetyTimer;
  late final AnimationController _exit;

  @override
  void initState() {
    super.initState();
    _exit = AnimationController(vsync: this, duration: _exitDuration);
    _minimumDisplayTimer = Timer(_minimumDisplay, _checkAndNavigate);
    _safetyTimer = Timer(_safetyTimeout, _onSafetyTimeout);
  }

  @override
  void dispose() {
    _minimumDisplayTimer?.cancel();
    _safetyTimer?.cancel();
    _exit.dispose();
    super.dispose();
  }

  /// Fades the content out, then navigates.
  Future<void> _leave(AuthState state) async {
    if (!MediaQuery.disableAnimationsOf(context)) {
      try {
        await _exit.forward().orCancel;
      } on TickerCanceled {
        return; // disposed mid-animation
      }
    }
    _navigateBasedOnState(state);
  }

  void _checkAndNavigate() {
    if (_hasNavigated || !mounted) return;

    final authState = context.read<AuthBloc>().state;

    if (authState is! AuthInitial && authState is! AuthLoading) {
      _hasNavigated = true;
      _safetyTimer?.cancel();
      _leave(authState);
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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (_minimumDisplayTimer?.isActive == false) {
          _checkAndNavigate();
        }
      },
      child: Scaffold(
        // Same colour as the native launch screen, so there is no flash.
        backgroundColor: SplashView.launchColor,
        body: SplashView(
          title: 'splash.app_name'.tr(),
          tagline: 'splash.tagline'.tr(),
          exit: _exit,
        ),
      ),
    );
  }
}
