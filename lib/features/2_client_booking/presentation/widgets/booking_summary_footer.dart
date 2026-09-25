import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../app/config/theme/app_colors.dart';
import '../../../../app/config/theme/app_text_styles.dart';
import '../../../../app/utils/formatters.dart';
import '../../../../shared/widgets/client_ui.dart';

/// Bottom bar of the booking steps: total price (with an optional caption
/// underneath) on the left and the gradient action button on the right.
class BookingSummaryFooter extends StatelessWidget {
  final double totalPrice;
  final int totalDurationMinutes;
  final String buttonText;
  final IconData buttonIcon;
  final VoidCallback? onButtonPressed;
  final bool isButtonLoading;
  final bool isButtonEnabled;

  /// Small label above the price. Defaults to "Total".
  final String? label;

  /// Line under the price. Defaults to the approximate duration.
  final String? caption;

  const BookingSummaryFooter({
    super.key,
    required this.totalPrice,
    required this.totalDurationMinutes,
    required this.buttonText,
    required this.buttonIcon,
    required this.onButtonPressed,
    this.isButtonLoading = false,
    this.isButtonEnabled = true,
    this.label,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ClientTheme.isDark(context);
    final cs = Theme.of(context).colorScheme;
    final effectiveOnPressed = isButtonEnabled ? onButtonPressed : null;
    final captionText = caption ??
        (totalDurationMinutes > 0
            ? 'client.booking.approx_duration'
                .tr(args: ['$totalDurationMinutes'])
            : null);

    return Container(
      decoration: BoxDecoration(
        color: ClientTheme.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: ClientTheme.border(context))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.15,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label ?? 'common.total_label'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClientTheme.caption(context),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppFormatters.formatCurrency(totalPrice),
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? cs.primary : AppColors.primaryDark,
                          ),
                        ),
                      ),
                      if (captionText != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          captionText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTheme.caption(context)
                              .copyWith(fontSize: 11.5),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: ClientPrimaryButton(
                    text: buttonText,
                    icon: buttonIcon,
                    onPressed: effectiveOnPressed,
                    isLoading: isButtonLoading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
