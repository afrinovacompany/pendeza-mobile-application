// auth_error_handler.dart
// A mixin and widget to handle AuthError states consistently across screens

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_chrome.dart';

/// A mixin that provides consistent auth error handling for StatefulWidgets.
///
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with AuthErrorHandlerMixin {
///   @override
///   Widget build(BuildContext context) {
///     return BlocListener<AuthBloc, AuthState>(
///       listener: authErrorListener,  // Use the mixin's listener
///       child: // ... your widget
///     );
///   }
/// }
/// ```
mixin AuthErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  /// The listener function to use with BlocListener
  void authErrorListener(BuildContext context, AuthState state) {
    if (state is AuthError) {
      _showErrorSnackBar(context, state);
    }
  }

  void _showErrorSnackBar(BuildContext context, AuthError error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error.message,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (error.recoveryHint != null) ...[
              const SizedBox(height: 4),
              Text(
                error.recoveryHint!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: error.isRecoverable
            ? SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            context.read<AuthBloc>().add(ClearAuthError());
          },
        )
            : null,
      ),
    );
  }
}

/// A widget that wraps screens needing auth and handles errors consistently.
///
/// Usage:
/// ```dart
/// AuthErrorHandler(
///   onError: (error) {
///     // Optional: additional error handling
///   },
///   child: YourScreen(),
/// )
/// ```
class AuthErrorHandler extends StatelessWidget {
  final Widget child;
  final void Function(AuthError error)? onError;
  final bool showLoadingOverlay;

  const AuthErrorHandler({
    super.key,
    required this.child,
    this.onError,
    this.showLoadingOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          _showErrorSnackBar(context, state);
          onError?.call(state);
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            child,
            if (showLoadingOverlay && state is AuthLoading)
              AuthLoadingOverlay(message: state.message),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, AuthError error) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error.message,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (error.recoveryHint != null) ...[
              const SizedBox(height: 4),
              Text(
                error.recoveryHint!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: error.isRecoverable
            ? SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            context.read<AuthBloc>().add(ClearAuthError());
          },
        )
            : null,
      ),
    );
  }

}

/// A specialized error display widget for inline error messages.
///
/// Use this for form-level errors or inline feedback.
class AuthErrorDisplay extends StatelessWidget {
  final AuthError? error;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const AuthErrorDisplay({
    super.key,
    this.error,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error!.message,
                  style: TextStyle(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (error!.recoveryHint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    error!.recoveryHint!,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (error!.isRecoverable && onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
          if (onDismiss != null) ...[
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              color: theme.colorScheme.onErrorContainer,
            ),
          ],
        ],
      ),
    );
  }
}

/// Extension to easily show auth-related dialogs
extension AuthErrorDialogs on BuildContext {
  /// Shows a dialog for non-recoverable errors that require user action
  Future<void> showAuthErrorDialog(AuthError error) {
    return showDialog(
      context: this,
      barrierDismissible: error.isRecoverable,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: const Text('Authentication Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error.message,
              textAlign: TextAlign.center,
            ),
            if (error.recoveryHint != null) ...[
              const SizedBox(height: 12),
              Text(
                error.recoveryHint!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (error.isRecoverable)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(ClearAuthError());
              },
              child: const Text('Try Again'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(error.isRecoverable ? 'Cancel' : 'OK'),
          ),
        ],
      ),
    );
  }
}