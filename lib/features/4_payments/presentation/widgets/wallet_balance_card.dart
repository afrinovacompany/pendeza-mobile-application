// =============================================================================
// Wallet Balance Card Widget
// =============================================================================
// Displays the user's wallet balance and whether they can afford the payment.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/wallet_model.dart';

class WalletBalanceCard extends StatelessWidget {
  final WalletModel wallet;
  final double requiredAmount;

  const WalletBalanceCard({
    super.key,
    required this.wallet,
    required this.requiredAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBalance = wallet.balance > 0;
    final canAfford = wallet.balance >= requiredAmount;
    final shortfall = requiredAmount - wallet.balance;

    return Container(
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: canAfford
            ? Colors.green.shade50
            : (hasBalance ? Colors.orange.shade50 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canAfford
              ? Colors.green.shade300
              : (hasBalance ? Colors.orange.shade300 : Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: canAfford
                    ? Colors.green.shade700
                    : (hasBalance ? Colors.orange.shade700 : Colors.grey.shade600),
              ),
              const SizedBox(width: AppConstants.padS),
              Text(
                'Your Wallet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.padS),

          // Balance row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Balance:', style: theme.textTheme.bodyMedium),
              Text(
                wallet.formattedBalance,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: canAfford ? Colors.green.shade700 : Colors.grey.shade700,
                ),
              ),
            ],
          ),

          // Insufficient balance warning
          if (!canAfford && hasBalance) ...[
            const SizedBox(height: AppConstants.padS),
            Container(
              padding: const EdgeInsets.all(AppConstants.padS),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: Colors.orange.shade800,
                  ),
                  const SizedBox(width: AppConstants.padS),
                  Expanded(
                    child: Text(
                      'Need TZS ${shortfall.toStringAsFixed(0)} more',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.padS),
            OutlinedButton.icon(
              onPressed: () {
                // Pop back from payment screen first, then navigate to wallet
                // This ensures proper navigation from root navigator to shell route
                context.pop(); // Close payment screen
                context.go('/client/wallet'); // Navigate to wallet
              },
              icon: const Icon(Icons.add_card),
              label: const Text('Top Up Wallet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade700),
              ),
            ),
          ]

          // Can afford message
          else if (canAfford) ...[
            const SizedBox(height: AppConstants.padS),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: AppConstants.padS),
                Text(
                  'You can pay with your wallet! ⚡',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}