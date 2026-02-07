import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../app/config/theme/app_colors.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/utils/formatters.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';

/// A reusable footer widget displaying booking summary (price, duration) and action button.
class BookingSummaryFooter extends StatelessWidget {
  final double totalPrice;
  final int totalDurationMinutes;
  final String buttonText;
  final IconData buttonIcon;
  final VoidCallback? onButtonPressed;
  final bool isButtonLoading;
  final bool isButtonEnabled;

  const BookingSummaryFooter({
    super.key,
    required this.totalPrice,
    required this.totalDurationMinutes,
    required this.buttonText,
    required this.buttonIcon,
    required this.onButtonPressed,
    this.isButtonLoading = false,
    this.isButtonEnabled = true, // Default to enabled
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveOnPressed = isButtonEnabled ? onButtonPressed : null;

    return Container(
      padding: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        // Use theme-aware shadows from AppColors
        boxShadow: theme.brightness == Brightness.light
            ? AppColors.lightShadowMd
            : AppColors.darkShadowMd,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusValL), // Use value constant
          topRight: Radius.circular(AppConstants.radiusValL),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Summary Column
          Expanded(
            flex: 2, // Give slightly more space to summary
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Key: "common.total_label"
                Text(
                  'common.total_label'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                // Price - Larger and bolder
                Text(
                  AppFormatters.formatCurrency(totalPrice),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Duration - Smaller, below price
                if (totalDurationMinutes > 0) ...[
                  const SizedBox(height: AppConstants.padXXS),
                  // Key: "client.booking.approx_duration" -> "Approx. {} minutes"
                  Text(
                    'client.booking.approx_duration'.tr(args: ['$totalDurationMinutes']),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(width: AppConstants.padM),
          // Action Button
          Expanded(
            flex: 3, // Give more space to button
            child: PrimaryGradientButton(
              text: buttonText,
              onPressed: effectiveOnPressed,
              iconData: buttonIcon,
              isLoading: isButtonLoading,
            ),
          ),
        ],
      ),
    );
  }
}