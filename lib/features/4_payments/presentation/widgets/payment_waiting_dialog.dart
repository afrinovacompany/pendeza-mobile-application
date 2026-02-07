// =============================================================================
// Payment Waiting Dialog
// =============================================================================
// Shows a dialog while waiting for USSD payment to be confirmed.
// =============================================================================

import 'package:flutter/material.dart';

/// Shows the waiting for payment dialog
void showPaymentWaitingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    routeSettings: const RouteSettings(name: 'PaymentDialog'),
    builder: (dialogContext) => const _PaymentWaitingDialog(),
  );
}

class _PaymentWaitingDialog extends StatelessWidget {
  const _PaymentWaitingDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Waiting for Payment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check your phone and enter your PIN to complete the payment.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue in Background'),
          ),
        ],
      ),
    );
  }
}