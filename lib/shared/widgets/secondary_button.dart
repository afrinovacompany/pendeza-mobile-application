import 'package:flutter/material.dart';
import '../../app/config/theme/app_constants.dart';
import '../../app/config/theme/app_text_styles.dart';

/// A custom secondary button for the application.
///
/// This button has a subtle, outlined style and is intended for actions
/// that are less important than the primary action on a screen, such as
/// "Cancel", "Go Back", or "View Details".
class SecondaryButton extends StatelessWidget {
  /// The callback that is called when the button is tapped.
  final VoidCallback? onPressed;

  /// The text to display inside the button.
  final String text;

  /// An optional icon to display to the left of the text.
  final IconData? iconData;

  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.padM,
          horizontal: AppConstants.padL,
        ),
        // Use the primary color for the border and text
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(
          color: theme.colorScheme.primary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.radiusM,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconData != null) ...[
            Icon(
              iconData,
              size: AppConstants.iconSizeM,
            ),
            const SizedBox(width: AppConstants.padXS),
          ],
          Text(
            text,
            // Use the button text style but with the primary color
            style: AppTextStyles.button.copyWith(
                color: theme.colorScheme.primary
            ),
          ),
        ],
      ),
    );
  }
}
