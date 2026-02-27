// =============================================================================
// Payment Info Card Widget
// =============================================================================
// Displays contextual information about the selected payment method.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import '../models/payment_method.dart';

class PaymentInfoCard extends StatelessWidget {
  final PaymentMethod selectedMethod;

  const PaymentInfoCard({
    super.key,
    required this.selectedMethod,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: theme.colorScheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppConstants.padS),
          Expanded(
            child: Text(
              selectedMethod.infoMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary.withOpacity(0.85),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
