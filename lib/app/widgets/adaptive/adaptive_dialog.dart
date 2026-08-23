import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'package:pendeza/app/config/platform_config.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/adaptive_theme.dart';

/// Shows a platform-adaptive alert dialog.
/// Uses AlertDialog on Android and CupertinoAlertDialog on iOS.
Future<T?> showAdaptiveDialog<T>({
  required BuildContext context,
  required String title,
  String? content,
  Widget? contentWidget,
  String? confirmText,
  String? cancelText,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  bool barrierDismissible = true,
  bool isDestructive = false,
}) {
  return showPlatformDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AdaptiveAlertDialog(
      title: title,
      content: content,
      contentWidget: contentWidget,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      isDestructive: isDestructive,
    ),
  );
}

/// Shows a platform-adaptive confirmation dialog with Yes/No options.
Future<bool> showAdaptiveConfirmDialog({
  required BuildContext context,
  required String title,
  String? content,
  String confirmText = 'Yes',
  String cancelText = 'No',
  bool isDestructive = false,
}) async {
  final result = await showAdaptiveDialog<bool>(
    context: context,
    title: title,
    content: content,
    confirmText: confirmText,
    cancelText: cancelText,
    isDestructive: isDestructive,
  );
  return result ?? false;
}

/// Shows a platform-adaptive delete confirmation dialog.
Future<bool> showAdaptiveDeleteDialog({
  required BuildContext context,
  String title = 'Delete',
  String content = 'Are you sure you want to delete this item? This action cannot be undone.',
}) {
  return showAdaptiveConfirmDialog(
    context: context,
    title: title,
    content: content,
    confirmText: 'Delete',
    cancelText: 'Cancel',
    isDestructive: true,
  );
}

/// A platform-adaptive alert dialog widget.
class AdaptiveAlertDialog extends StatelessWidget {
  const AdaptiveAlertDialog({
    super.key,
    required this.title,
    this.content,
    this.contentWidget,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  final String title;
  final String? content;
  final Widget? contentWidget;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> actions = [];

    if (cancelText != null || onCancel != null) {
      actions.add(
        PlatformDialogAction(
          onPressed: onCancel ?? () => Navigator.of(context).pop(),
          child: Text(cancelText ?? 'Cancel'),
          material: (_, _) => MaterialDialogActionData(
            style: TextButton.styleFrom(
              foregroundColor:
                  isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          cupertino: (_, _) => CupertinoDialogActionData(
            isDefaultAction: !isDestructive,
          ),
        ),
      );
    }

    if (confirmText != null || onConfirm != null) {
      actions.add(
        PlatformDialogAction(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          child: Text(confirmText ?? 'OK'),
          material: (_, _) => MaterialDialogActionData(
            style: TextButton.styleFrom(
              foregroundColor: isDestructive
                  ? AppColors.error
                  : (isDark ? AppColors.primaryLight : AppColors.primary),
            ),
          ),
          cupertino: (_, _) => CupertinoDialogActionData(
            isDestructiveAction: isDestructive,
            isDefaultAction: !isDestructive && cancelText == null,
          ),
        ),
      );
    }

    // If no actions specified, add default OK button
    if (actions.isEmpty) {
      actions.add(
        PlatformDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
          cupertino: (_, _) => CupertinoDialogActionData(
            isDefaultAction: true,
          ),
        ),
      );
    }

    return PlatformAlertDialog(
      title: Text(title),
      content: contentWidget ?? (content != null ? Text(content!) : null),
      actions: actions,
      material: (_, _) => MaterialAlertDialogData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        titleTextStyle: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AdaptiveTheme.adaptiveCardRadius,
        ),
      ),
      cupertino: (_, _) => CupertinoAlertDialogData(),
    );
  }
}

/// Shows a platform-adaptive action sheet (bottom sheet on Android).
Future<T?> showAdaptiveActionSheet<T>({
  required BuildContext context,
  String? title,
  String? message,
  required List<AdaptiveSheetAction<T>> actions,
  AdaptiveSheetAction<T>? cancelAction,
}) {
  if (PlatformConfig.useCupertino) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: title != null ? Text(title) : null,
        message: message != null ? Text(message) : null,
        actions: actions
            .map((action) => CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(context).pop(action.value);
                    action.onPressed?.call();
                  },
                  isDefaultAction: action.isDefault,
                  isDestructiveAction: action.isDestructive,
                  child: Text(action.label),
                ))
            .toList(),
        cancelButton: cancelAction != null
            ? CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop(cancelAction.value);
                  cancelAction.onPressed?.call();
                },
                isDefaultAction: cancelAction.isDefault,
                child: Text(cancelAction.label),
              )
            : CupertinoActionSheetAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
      ),
    );
  }

  // Material bottom sheet
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              if (title != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              // Message
              if (message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 8),
              // Actions
              ...actions.map((action) => ListTile(
                    onTap: () {
                      Navigator.of(context).pop(action.value);
                      action.onPressed?.call();
                    },
                    leading: action.icon != null
                        ? Icon(
                            action.icon,
                            color: action.isDestructive
                                ? AppColors.error
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary),
                          )
                        : null,
                    title: Text(
                      action.label,
                      style: TextStyle(
                        color: action.isDestructive
                            ? AppColors.error
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary),
                        fontWeight:
                            action.isDefault ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  )),
              // Cancel
              if (cancelAction != null)
                ListTile(
                  onTap: () {
                    Navigator.of(context).pop(cancelAction.value);
                    cancelAction.onPressed?.call();
                  },
                  title: Text(
                    cancelAction.label,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

/// Represents an action in an adaptive action sheet.
class AdaptiveSheetAction<T> {
  const AdaptiveSheetAction({
    required this.label,
    this.value,
    this.icon,
    this.onPressed,
    this.isDefault = false,
    this.isDestructive = false,
  });

  final String label;
  final T? value;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isDefault;
  final bool isDestructive;
}

/// Shows a platform-adaptive loading dialog.
Future<void> showAdaptiveLoadingDialog({
  required BuildContext context,
  String? message,
  bool barrierDismissible = false,
}) {
  return showPlatformDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AdaptiveLoadingDialog(message: message),
  );
}

/// A platform-adaptive loading dialog widget.
class AdaptiveLoadingDialog extends StatelessWidget {
  const AdaptiveLoadingDialog({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (PlatformConfig.useCupertino) {
      return CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 14),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message!),
              ],
            ],
          ),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AdaptiveTheme.adaptiveCardRadius,
      ),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows a platform-adaptive snackbar/toast.
void showAdaptiveSnackBar({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
  Color? backgroundColor,
  bool isError = false,
  bool isSuccess = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  Color bgColor;
  if (backgroundColor != null) {
    bgColor = backgroundColor;
  } else if (isError) {
    bgColor = AppColors.error;
  } else if (isSuccess) {
    bgColor = AppColors.success;
  } else {
    bgColor = isDark ? AppColors.darkSurfaceVariant : AppColors.textPrimary;
  }

  final textColor = (isError || isSuccess || !isDark)
      ? Colors.white
      : AppColors.darkTextPrimary;

  if (PlatformConfig.useCupertino) {
    // Show a Cupertino-style overlay notification
    _showCupertinoToast(
      context: context,
      message: message,
      duration: duration,
      backgroundColor: bgColor,
      textColor: textColor,
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: textColor)),
        duration: duration,
        backgroundColor: bgColor,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

void _showCupertinoToast({
  required BuildContext context,
  required String message,
  required Duration duration,
  required Color backgroundColor,
  required Color textColor,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 60,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 200),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  Future.delayed(duration, () {
    entry.remove();
  });
}
