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
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: Text(
              selectedMethod.infoMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}