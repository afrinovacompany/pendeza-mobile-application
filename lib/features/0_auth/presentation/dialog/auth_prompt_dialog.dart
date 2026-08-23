import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_router.dart';
import '../auth_return_store.dart';

/// A simple, beautiful dialog that prompts guest users to sign in.
class AuthPromptDialog extends StatelessWidget {
  final String featureName;
  final String? customMessage;
  final IconData? icon;
  final String? returnRoute;
  final Map<String, dynamic>? returnData;

  const AuthPromptDialog({
    super.key,
    required this.featureName,
    this.customMessage,
    this.icon,
    this.returnRoute,
    this.returnData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest,
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon ?? CupertinoIcons.lock_shield_fill,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Sign In Required',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Simple Message
              Text(
                customMessage ?? _getMessage(featureName),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    AuthReturnStore.setPending(returnRoute);
                    context.pop();
                    context.push(
                      AppRoutes.login,
                      extra: {
                        'returnRoute': returnRoute,
                        'returnData': returnData,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.arrow_right_circle_fill, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Sign In',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Create Account Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    AuthReturnStore.setPending(returnRoute);
                    context.pop();
                    context.push(
                      AppRoutes.signup,
                      extra: {
                        'returnRoute': returnRoute,
                        'returnData': returnData,
                      },
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Create Account',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Continue Browsing
              TextButton(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                child: Text(
                  'Continue Browsing',
                  style: TextStyle(
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMessage(String feature) {
    switch (feature.toLowerCase()) {
      case 'booking':
      case 'book':
        return 'Sign in to book and manage your appointments';
      case 'favorite':
      case 'save':
        return 'Sign in to save your favorite salons';
      case 'review':
        return 'Sign in to share your experience';
      default:
        return 'Sign in to unlock all features';
    }
  }

  /// Static method to show the dialog
  static Future<void> show(
      BuildContext context, {
        required String featureName,
        String? customMessage,
        IconData? icon,
        String? returnRoute,
        Map<String, dynamic>? returnData,
      }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AuthPromptDialog(
        featureName: featureName,
        customMessage: customMessage,
        icon: icon,
        returnRoute: returnRoute,
        returnData: returnData,
      ),
    );
  }
}

/// Helper extension
extension AuthPromptExtension on BuildContext {
  Future<void> requireAuth({
    required String featureName,
    String? customMessage,
    IconData? icon,
    String? returnRoute,
    Map<String, dynamic>? returnData,
  }) {
    return AuthPromptDialog.show(
      this,
      featureName: featureName,
      customMessage: customMessage,
      icon: icon,
      returnRoute: returnRoute,
      returnData: returnData,
    );
  }
}