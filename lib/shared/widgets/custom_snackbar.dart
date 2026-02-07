import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

enum SnackBarType { success, error, info, warning }

/// Enhanced snackbar with modern animations and iOS-style design
class CustomSnackBar {
  static void show(
      BuildContext context, {
        required String message,
        required SnackBarType type,
        Duration duration = const Duration(seconds: 4),
        VoidCallback? onAction,
        String? actionLabel,
      }) {
    final theme = Theme.of(context);
    final colors = _getColors(type, theme);
    final icon = _getIcon(type);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: colors.icon, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onAction != null && actionLabel != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.bg,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          duration: duration,
        ),
      );
  }

  static ({Color bg, Color icon, Color iconBg}) _getColors(
      SnackBarType type, ThemeData theme) {
    switch (type) {
      case SnackBarType.success:
        return (
        bg: const Color(0xFF00B894),
        icon: Colors.white,
        iconBg: Colors.white.withValues(alpha: 0.25),
        );
      case SnackBarType.error:
        return (
        bg: const Color(0xFFFF6B6B),
        icon: Colors.white,
        iconBg: Colors.white.withValues(alpha: 0.25),
        );
      case SnackBarType.warning:
        return (
        bg: const Color(0xFFFDCB6E),
        icon: Colors.white,
        iconBg: Colors.white.withValues(alpha: 0.25),
        );
      case SnackBarType.info:
      return (
        bg: const Color(0xFF2D3436),
        icon: Colors.white,
        iconBg: Colors.white.withValues(alpha: 0.25),
        );
    }
  }

  static IconData _getIcon(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return CupertinoIcons.check_mark_circled_solid;
      case SnackBarType.error:
        return CupertinoIcons.xmark_circle_fill;
      case SnackBarType.warning:
        return CupertinoIcons.exclamationmark_triangle_fill;
      case SnackBarType.info:
      return CupertinoIcons.info_circle_fill;
    }
  }
}