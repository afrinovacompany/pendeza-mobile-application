// =============================================================================
// Payment Method Option Widget
// =============================================================================
// A selectable payment method card with icon, title, subtitle, and badge.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import '../models/payment_method.dart';

class PaymentMethodOption extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final bool isDisabled;
  final String? badge;
  final Color? badgeColor;
  final String? customSubtitle;
  final VoidCallback? onTap;

  const PaymentMethodOption({
    super.key,
    required this.method,
    required this.isSelected,
    this.isDisabled = false,
    this.badge,
    this.badgeColor,
    this.customSubtitle,
    this.onTap,
  });

  IconData get _icon {
    switch (method) {
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet;
      case PaymentMethod.ussdPush:
        return Icons.phone_android;
      case PaymentMethod.payByLink:
        return Icons.language;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIsSelected = isSelected && !isDisabled;

    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(AppConstants.padM),
          decoration: BoxDecoration(
            border: Border.all(
              color: effectiveIsSelected
                  ? theme.colorScheme.primary
                  : Colors.grey.shade300,
              width: effectiveIsSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: effectiveIsSelected
                ? theme.colorScheme.primary.withOpacity(0.05)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: effectiveIsSelected
                      ? theme.colorScheme.primary
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _icon,
                  color: effectiveIsSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: AppConstants.padM),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          method.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: effectiveIsSelected
                                ? theme.colorScheme.primary
                                : Colors.black87,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor ?? Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customSubtitle ?? method.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Radio button
              Radio<PaymentMethod>(
                value: method,
                groupValue: isDisabled ? null : (isSelected ? method : null),
                onChanged: isDisabled
                    ? null
                    : (value) {
                  if (onTap != null) onTap!();
                },
                toggleable: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}