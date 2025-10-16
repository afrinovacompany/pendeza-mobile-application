import 'package:flutter/material.dart';
import '../../app/config/theme/app_colors.dart';
import '../../app/config/theme/app_constants.dart';
import '../../app/config/theme/app_text_styles.dart';

/// A custom primary button for the application that uses the predefined
/// gradient and shadow styles.
///
/// This button is highly reusable and should be used for all primary
/// actions, such as "Login", "Sign Up", or "Confirm Booking".
class PrimaryGradientButton extends StatelessWidget {
  /// The callback that is called when the button is tapped.
  final VoidCallback? onPressed;

  /// The text to display inside the button.
  final String text;

  /// An optional icon to display to the left of the text.
  final IconData? iconData;

  /// A boolean to indicate if the button is in a loading state.
  /// When true, it shows a CircularProgressIndicator instead of the text.
  final bool isLoading;

  const PrimaryGradientButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.iconData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if the button is enabled. A null onPressed callback
    // or isLoading state means the button is disabled.
    final bool isEnabled = onPressed != null && !isLoading;

    return Container(
      // We use the predefined buttonDecoration from AppColors.
      // This ensures all primary buttons have the same gradient, shadow, and radius.
      decoration: isEnabled
          ? AppColors.buttonDecoration
          : AppColors.buttonDecoration.copyWith(
        gradient: LinearGradient(
          colors: [Colors.grey.shade400, Colors.grey.shade500],
        ),
        boxShadow: const [], // No shadow for disabled state
      ),
      child: Material(
        // Material widget is used to provide the ripple effect on tap.
        color: Colors.transparent,
        child: InkWell(
          // Only enable the tap functionality if the button is enabled.
          onTap: isEnabled ? onPressed : null,
          borderRadius: AppConstants.radiusM,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.padM,
              horizontal: AppConstants.padL,
            ),
            child: Center(
              // If in loading state, show a spinner. Otherwise, show the text/icon.
              child: isLoading
                  ? const SizedBox(
                height: 24, // Consistent height for the spinner
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                // **FIX: Wrap the Text widget in Expanded to prevent horizontal overflow**
                children: [
                  if (iconData != null) ...[
                    Icon(
                      iconData,
                      color: Colors.white,
                      size: AppConstants.iconSizeM,
                    ),
                    const SizedBox(width: AppConstants.padXS),
                  ],
                  // Use Flexible instead of Expanded here to allow the Row to shrink
                  // while still applying constraints to the text, which is the actual issue.
                  // For a button, Flexible combined with text alignment gives the best result
                  // when the button itself is constrained (like in the floating footer).
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center, // Center the text if space is tight
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
