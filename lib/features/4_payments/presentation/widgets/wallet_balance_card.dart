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

    final Color accentColor = canAfford
        ? const Color(0xFF10B981)
        : (hasBalance ? const Color(0xFFF59E0B) : Colors.grey.shade500);

    return Container(
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.padS),
              Text(
                'Wallet Balance',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                wallet.formattedBalance,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),

          // Insufficient balance warning
          if (!canAfford && hasBalance) ...[
            const SizedBox(height: AppConstants.padS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.padS,
                vertical: AppConstants.padXS,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: accentColor,
                  ),
                  const SizedBox(width: AppConstants.padXS),
                  Expanded(
                    child: Text(
                      'TZS ${shortfall.toStringAsFixed(0)} more needed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      context.pop();
                      context.go('/client/wallet');
                    },
                    icon: Icon(Icons.add_rounded, size: 16, color: accentColor),
                    label: Text(
                      'Top Up',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ]

          // Can afford message
          else if (canAfford) ...[
            const SizedBox(height: AppConstants.padXS),
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: accentColor,
                ),
                const SizedBox(width: AppConstants.padXS),
                Text(
                  'Sufficient balance for this payment',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accentColor,
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
