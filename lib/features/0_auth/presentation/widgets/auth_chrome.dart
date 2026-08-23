import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/widgets/adaptive/adaptive_app_bar.dart';

/// Shared first-run / auth layout tokens.
class AuthChrome {
  AuthChrome._();

  static const double pagePadding = AppConstants.padL;
  static const double titleGap = 8;
  static const double headerGap = AppConstants.padXL;
  static const double fieldGap = AppConstants.padL;
  static const double actionGap = AppConstants.padM;
  static const double iconSize = 80;
  static const double ctaHeight = 56;
  static const double subtitleOpacity = 0.65;
}

/// Transparent surface app bar with a back button only when the route can pop.
PreferredSizeWidget? authAppBar(
  BuildContext context, {
  bool isLoading = false,
}) {
  if (!context.canPop()) return null;

  final theme = Theme.of(context);
  return AdaptiveAppBar(
    title: '',
    automaticallyImplyLeading: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: theme.colorScheme.onSurface,
    leading: AdaptiveBackButton(
      color: theme.colorScheme.onSurface,
      onPressed: isLoading ? null : () => context.pop(),
    ),
  );
}

/// Scaffold used by Login, Signup, Phone, OTP, and Role Selection.
class AuthScaffold extends StatelessWidget {
  final Widget body;
  final bool isLoading;
  final String? loadingMessage;

  const AuthScaffold({
    super.key,
    required this.body,
    this.isLoading = false,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: authAppBar(context, isLoading: isLoading),
      body: SafeArea(
        child: Stack(
          children: [
            body,
            if (isLoading) AuthLoadingOverlay(message: loadingMessage),
          ],
        ),
      ),
    );
  }
}

/// Centered, padded, scrollable auth page body.
class AuthPageBody extends StatelessWidget {
  final Widget child;
  final bool expandToFill;

  const AuthPageBody({
    super.key,
    required this.child,
    this.expandToFill = false,
  });

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.all(AuthChrome.pagePadding);

    if (!expandToFill) {
      return Center(
        child: SingleChildScrollView(
          padding: padding,
          child: child,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Title + subtitle block used across first-run screens.
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leading;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (leading != null) ...[
          Center(child: leading!),
          const SizedBox(height: AuthChrome.fieldGap),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AuthChrome.titleGap),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(
              alpha: AuthChrome.subtitleOpacity,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared loading overlay for auth screens.
///
/// Dimmed full-screen barrier with the Lottie loader and an optional status
/// line (e.g. "Sending verification code...").
class AuthLoadingOverlay extends StatelessWidget {
  static const assetPath = 'assets/lottie/loading.json';

  final String? message;

  const AuthLoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = message;

    return AbsorbPointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: ColoredBox(
              color: theme.colorScheme.scrim.withValues(alpha: 0.5 * value),
              child: Center(child: child),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AuthChrome.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                assetPath,
                width: 160,
                height: 160,
                repeat: true,
                fit: BoxFit.contain,
              ),
              if (label != null && label.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onInverseSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

ButtonStyle authOutlinedButtonStyle(ThemeData theme) {
  return OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16),
    foregroundColor: theme.colorScheme.primary,
    side: BorderSide(
      color: theme.colorScheme.primary.withValues(alpha: 0.3),
      width: 1.5,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );
}
