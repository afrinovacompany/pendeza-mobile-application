import 'package:flutter/material.dart';
import '../../app/config/theme/app_constants.dart';
import 'primary_gradient_button.dart';

/// A reusable widget to display for empty states or error messages.
///
/// It provides a consistent layout with an icon, a title, a message,
/// and an optional "retry" action button.
class EmptyStateWidget extends StatelessWidget {
  /// The icon to display at the top of the widget.
  final IconData iconData;

  /// The main title text.
  final String title;

  /// The descriptive message text below the title.
  final String message;

  /// The text for the optional action button. If null, no button is shown.
  final String? actionText;

  /// The callback to execute when the action button is tapped.
  final VoidCallback? onActionPressed;

  const EmptyStateWidget({
    super.key,
    required this.iconData,
    required this.title,
    required this.message,
    this.actionText,
    this.onActionPressed,
  });

  /// A specific constructor for a generic "Not Found" state.
  const EmptyStateWidget.notFound({
    super.key,
    IconData? iconData, // FIX: Added optional iconData parameter
    required this.message,
    this.onActionPressed,
    this.actionText,
  })  : iconData = iconData ?? Icons.search_off_rounded, // Use provided icon or default
        title = 'Nothing Found';

  /// A specific constructor for a generic "Error" state.
  const EmptyStateWidget.error({
    super.key,
    IconData? iconData, // FIX: Added optional iconData parameter
    required this.message,
    this.onActionPressed,
  })  : iconData = iconData ?? Icons.error_outline_rounded, // Use provided icon or default
        title = 'An Error Occurred',
        actionText = 'Try Again';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 80,
              // FIX: Replaced withOpacity(0.6) with withAlpha(153)
              color: theme.colorScheme.primary.withAlpha(153), // 0.6 * 255
            ),
            const SizedBox(height: AppConstants.padL),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: AppConstants.padS),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                // FIX: Replaced withOpacity(0.7) with withAlpha(179)
                color: theme.textTheme.bodyMedium?.color?.withAlpha(179), // 0.7 * 255
              ),
            ),
            if (actionText != null) ...[
              const SizedBox(height: AppConstants.padL),
              PrimaryGradientButton(
                onPressed: onActionPressed,
                text: actionText!,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
