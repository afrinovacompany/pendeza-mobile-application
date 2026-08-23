import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:pendeza/shared/models/transaction_model.dart';

/// Transaction History Screen
///
/// Shows complete list of all transactions with:
/// - Filtering by type
/// - Search functionality
/// - Detailed transaction info
/// - Export capabilities (future)
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  TransactionType? _filterType;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: Text('Please sign in')),
      );
    }

    final userId = authState.user.uid;

    return BlocProvider(
      create: (context) => WalletBloc(
        walletRepository: context.read(),
        paymentService: context.read(),
      )..add(LoadWallet(userId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transaction History'),
          centerTitle: true,
          actions: [
            PopupMenuButton<TransactionType?>(
              icon: const Icon(CupertinoIcons.slider_horizontal_3),
              tooltip: 'Filter',
              onSelected: (type) {
                setState(() => _filterType = type);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('All Transactions'),
                ),
                const PopupMenuItem(
                  value: TransactionType.deposit,
                  child: Text('Deposits'),
                ),
                const PopupMenuItem(
                  value: TransactionType.payment,
                  child: Text('Payments'),
                ),
                const PopupMenuItem(
                  value: TransactionType.refund,
                  child: Text('Refunds'),
                ),
              ],
            ),
          ],
        ),
        body: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            if (state is WalletLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is WalletError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<WalletBloc>()
                          .add(LoadWallet(userId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            List<TransactionModel> transactions = [];

            if (state is WalletTransactionsLoaded) {
              transactions = state.transactions;
            } else if (state is WalletLoaded) {
              transactions = state.recentTransactions;
            }

            // Apply filter
            if (_filterType != null) {
              transactions = transactions
                  .where((t) => t.type == _filterType)
                  .toList();
            }

            return _buildTransactionsList(context, transactions);
          },
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
      BuildContext context,
      List<TransactionModel> transactions,
      ) {
    final theme = Theme.of(context);

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppConstants.padL),
            Text(
              _filterType == null
                  ? 'No transactions yet'
                  : 'No ${_filterType!.name} transactions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.padS),
            Text(
              'Your transactions will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Group transactions by date
    final groupedTransactions = _groupTransactionsByDate(transactions);

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.padL),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final date = groupedTransactions.keys.elementAt(index);
        final dayTransactions = groupedTransactions[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.padM,
                horizontal: AppConstants.padS,
              ),
              child: Text(
                _formatDateHeader(date),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            // Transactions for this date
            ...dayTransactions.map(
                  (transaction) => _buildTransactionCard(context, transaction),
            ),

            const SizedBox(height: AppConstants.padM),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(
      BuildContext context,
      TransactionModel transaction,
      ) {
    final theme = Theme.of(context);

    // Determine icon, color, and sign
    IconData icon;
    Color iconColor;
    bool isCredit;

    switch (transaction.type) {
      case TransactionType.deposit:
        icon = CupertinoIcons.arrow_down_circle_fill;
        iconColor = Colors.green;
        isCredit = true;
        break;
      case TransactionType.payment:
        icon = CupertinoIcons.arrow_up_circle_fill;
        iconColor = Colors.red;
        isCredit = false;
        break;
      case TransactionType.refund:
        icon = CupertinoIcons.arrow_counterclockwise_circle_fill;
        iconColor = Colors.blue;
        isCredit = true;
        break;
      case TransactionType.payout:
        icon = CupertinoIcons.money_dollar_circle;
        iconColor = Colors.orange;
        isCredit = false;
        break;
      default:
        icon = CupertinoIcons.arrow_right_arrow_left_circle;
        iconColor = theme.colorScheme.primary;
        isCredit = false;
    }

    return GestureDetector(
      onTap: () => _showTransactionDetails(context, transaction),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.padM),
        padding: const EdgeInsets.all(AppConstants.padL),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),

            const SizedBox(width: AppConstants.padM),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.typeLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(transaction.status)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          transaction.statusLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getStatusColor(transaction.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time
                      Text(
                        DateFormat('h:mm a').format(transaction.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'} ${transaction.formattedAmount}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCredit ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Group transactions by date
  Map<DateTime, List<TransactionModel>> _groupTransactionsByDate(
      List<TransactionModel> transactions,
      ) {
    final Map<DateTime, List<TransactionModel>> grouped = {};

    for (final transaction in transactions) {
      final date = DateTime(
        transaction.createdAt.year,
        transaction.createdAt.month,
        transaction.createdAt.day,
      );

      if (grouped.containsKey(date)) {
        grouped[date]!.add(transaction);
      } else {
        grouped[date] = [transaction];
      }
    }

    return grouped;
  }

  /// Format date header (e.g., "Today", "Yesterday", "Jan 15, 2025")
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  /// Get status color
  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.reversed:
        return Colors.blue;
    }
  }

  /// Show transaction details dialog
  void _showTransactionDetails(
      BuildContext context,
      TransactionModel transaction,
      ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.padXL),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.padL),

            Text(
              'Transaction Details',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppConstants.padXL),

            _buildDetailRow('Type', transaction.typeLabel),
            _buildDetailRow('Amount', transaction.formattedAmount),
            _buildDetailRow('Status', transaction.statusLabel),
            _buildDetailRow(
              'Date',
              DateFormat('MMM d, yyyy • h:mm a').format(transaction.createdAt),
            ),
            _buildDetailRow('Transaction ID', transaction.id),
            if (transaction.gatewayOrderId.isNotEmpty)
              _buildDetailRow('Reference', transaction.gatewayOrderId),
            if (transaction.description != null)
              _buildDetailRow('Description', transaction.description!),

            const SizedBox(height: AppConstants.padXL),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.padM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}