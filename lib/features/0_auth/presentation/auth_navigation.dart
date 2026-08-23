import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_router.dart';
import 'auth_return_store.dart';
import 'bloc/auth_state.dart';

const _authLocations = {
  AppRoutes.login,
  AppRoutes.signup,
  AppRoutes.forgotPassword,
  AppRoutes.phoneAuth,
  AppRoutes.otp,
};

/// Leaves the auth stack after a completed sign-in.
///
/// Owners/admins never inherit a guest booking return path. Clients go to
/// that pending booking route when one exists, otherwise client home.
/// No-ops if GoRouter already moved us off the auth screens.
void goAfterAuthenticated(BuildContext context, Authenticated state) {
  if (!context.mounted) return;
  final location = GoRouterState.of(context).matchedLocation;
  if (!_authLocations.contains(location)) {
    return;
  }
  if (state.user.isAdmin) {
    AuthReturnStore.clear();
    context.go(AppRoutes.adminHome);
    return;
  }
  if (state.user.role == 'owner') {
    AuthReturnStore.clear();
    context.go(AppRoutes.ownerHome);
    return;
  }
  context.go(AuthReturnStore.consume() ?? AppRoutes.clientHome);
}
