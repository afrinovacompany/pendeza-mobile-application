import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/transaction_model.dart';

import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminManageTransactionsScreen extends StatefulWidget {
  const AdminManageTransactionsScreen({super.key});

  @override
  State<AdminManageTransactionsScreen> createState() =>
      _AdminManageTransactionsScreenState();
}

class _AdminManageTransactionsScreenState
    extends State<AdminManageTransactionsScreen> {
  String? _selectedType;
  String? _selectedStatus;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    context.read<AdminBloc>().add(LoadAllTransactions(
          filterType: _selectedType,
          filterStatus: _selectedStatus,
        ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        backgroundColor:
            isDark ? AppColors.darkSurfaceVariant : theme.colorScheme.surface,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: isDark
          ? AppColors.darkBackground
          : theme.scaffoldBackgroundColor.withAlpha(245),
      body: Column(
        children: [
          // Filters Section
          _buildFiltersSection(theme),

          // Transactions List
          Expanded(
            child: BlocBuilder<AdminBloc, AdminState>(
              builder: (context, state) {
                if (state is AdminLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AdminError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: AppConstants.padM),
                        Text(state.message),
                        const SizedBox(height: AppConstants.padM),
                        ElevatedButton(
                          onPressed: _loadTransactions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AdminLoaded) {
                  final transactions = _filterTransactions(state.transactions);

                  if (transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.doc_text,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: AppConstants.padM),
                          Text(
                            'No transactions found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: AppConstants.padS),
                          Text(
                            'Transactions will appear here when users make payments',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildTransactionsList(transactions, theme, state);
                }

                return const Center(child: Text('Unknown state'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by transaction ID or user...',
              prefixIcon: const Icon(CupertinoIcons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.padM,
                vertical: AppConstants.padS,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppConstants.padM),

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Type Filter
                _buildFilterDropdown(
                  label: 'Type',
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Types')),
                    DropdownMenuItem(value: 'deposit', child: Text('Deposits')),
                    DropdownMenuItem(value: 'payment', child: Text('Payments')),
                    DropdownMenuItem(value: 'payout', child: Text('Payouts')),
                    DropdownMenuItem(value: 'refund', child: Text('Refunds')),
                    DropdownMenuItem(
                        value: 'commission', child: Text('Commissions')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedType = value);
                    _loadTransactions();
                  },
                ),
                const SizedBox(width: AppConstants.padM),

                // Status Filter
                _buildFilterDropdown(
                  label: 'Status',
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Status')),
                    DropdownMenuItem(
                        value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                        value: 'processing', child: Text('Processing')),
                    DropdownMenuItem(value: 'failed', child: Text('Failed')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _loadTransactions();
                  },
                ),

                // Clear Filters Button
                if (_selectedType != null || _selectedStatus != null) ...[
                  const SizedBox(width: AppConstants.padM),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedType = null;
                        _selectedStatus = null;
                      });
                      _loadTransactions();
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String?>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: Text(label),
        ),
      ),
    );
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions) {
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isEmpty) return transactions;

    return transactions.where((t) {
      return t.id.toLowerCase().contains(searchTerm) ||
          t.userId.toLowerCase().contains(searchTerm) ||
          t.gatewayOrderId.toLowerCase().contains(searchTerm) ||
          (t.description?.toLowerCase().contains(searchTerm) ?? false);
    }).toList();
  }

  Widget _buildTransactionsList(
    List<TransactionModel> transactions,
    ThemeData theme,
    AdminLoaded state,
  ) {
    // Calculate summary stats
    final totalAmount = transactions.fold<double>(
      0,
      (sum, t) => sum + (t.isCompleted ? t.amount : 0),
    );
    final depositTotal = transactions
        .where((t) => t.isDeposit && t.isCompleted)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final paymentTotal = transactions
        .where((t) => t.isPayment && t.isCompleted)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final pendingCount = transactions.where((t) => t.isPending).length;

    return Column(
      children: [
        // Summary Stats
        Container(
          padding: const EdgeInsets.all(AppConstants.padM),
          child: Row(
            children: [
              _buildStatChip(
                'Total',
                'TZS ${NumberFormat.compact().format(totalAmount)}',
                AppColors.primary,
              ),
              const SizedBox(width: AppConstants.padS),
              _buildStatChip(
                'Deposits',
                'TZS ${NumberFormat.compact().format(depositTotal)}',
                AppColors.success,
              ),
              const SizedBox(width: AppConstants.padS),
              _buildStatChip(
                'Payments',
                'TZS ${NumberFormat.compact().format(paymentTotal)}',
                AppColors.accent2,
              ),
              const SizedBox(width: AppConstants.padS),
              _buildStatChip(
                'Pending',
                pendingCount.toString(),
                AppColors.warning,
              ),
            ],
          ),
        ),

        // Count indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padM),
          child: Row(
            children: [
              Text(
                '${transactions.length} transactions',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.padS),

        // Transactions List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.padM),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionCard(transaction, theme, state);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.padS,
          vertical: AppConstants.padS,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    TransactionModel transaction,
    ThemeData theme,
    AdminLoaded state,
  ) {
    final user = state.users.where((u) => u.uid == transaction.userId).firstOrNull;
    final userName = user?.fullName ?? 'Unknown User';

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.padS),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction, userName),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padM),
          child: Row(
            children: [
              // Type Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getTypeColor(transaction.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getTypeIcon(transaction.type),
                  color: _getTypeColor(transaction.type),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppConstants.padM),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          transaction.typeLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppConstants.padS),
                        _buildStatusBadge(transaction.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy • HH:mm')
                          .format(transaction.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_isCredit(transaction.type) ? '+' : '-'} ${transaction.formattedAmount}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isCredit(transaction.type)
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                  Text(
                    transaction.provider,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TransactionStatus status) {
    Color color;
    switch (status) {
      case TransactionStatus.completed:
        color = AppColors.success;
        break;
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        color = AppColors.warning;
        break;
      case TransactionStatus.failed:
        color = AppColors.error;
        break;
      case TransactionStatus.reversed:
        color = AppColors.accent2;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return AppColors.success;
      case TransactionType.payment:
        return AppColors.primary;
      case TransactionType.payout:
        return AppColors.accent2;
      case TransactionType.refund:
        return Colors.blue;
      case TransactionType.commission:
        return AppColors.accent;
      case TransactionType.promotion:
        return Colors.purple;
      case TransactionType.adjustment:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return CupertinoIcons.arrow_down_circle_fill;
      case TransactionType.payment:
        return CupertinoIcons.creditcard_fill;
      case TransactionType.payout:
        return CupertinoIcons.arrow_up_circle_fill;
      case TransactionType.refund:
        return CupertinoIcons.arrow_uturn_left_circle_fill;
      case TransactionType.commission:
        return CupertinoIcons.percent;
      case TransactionType.promotion:
        return CupertinoIcons.tag_fill;
      case TransactionType.adjustment:
        return CupertinoIcons.slider_horizontal_3;
    }
  }

  bool _isCredit(TransactionType type) {
    return type == TransactionType.deposit ||
        type == TransactionType.refund;
  }

  void _showTransactionDetails(TransactionModel transaction, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppConstants.padL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppConstants.padL),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _getTypeColor(transaction.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getTypeIcon(transaction.type),
                        color: _getTypeColor(transaction.type),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppConstants.padM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.typeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          _buildStatusBadge(transaction.status),
                        ],
                      ),
                    ),
                    Text(
                      '${_isCredit(transaction.type) ? '+' : '-'} ${transaction.formattedAmount}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isCredit(transaction.type)
                                ? AppColors.success
                                : AppColors.error,
                          ),
                    ),
                  ],
                ),

                const Divider(height: AppConstants.padXL),

                // Details
                _buildDetailRow('Transaction ID', transaction.id),
                _buildDetailRow('Gateway ID', transaction.gatewayOrderId),
                _buildDetailRow('User', userName),
                _buildDetailRow('User ID', transaction.userId),
                if (transaction.relatedUserId != null)
                  _buildDetailRow('Related User', transaction.relatedUserId!),
                if (transaction.referenceId != null)
                  _buildDetailRow('Reference ID', transaction.referenceId!),
                _buildDetailRow('Provider', transaction.provider),
                _buildDetailRow(
                  'Created At',
                  DateFormat('MMM dd, yyyy • HH:mm:ss')
                      .format(transaction.createdAt),
                ),
                if (transaction.completedAt != null)
                  _buildDetailRow(
                    'Completed At',
                    DateFormat('MMM dd, yyyy • HH:mm:ss')
                        .format(transaction.completedAt!),
                  ),
                if (transaction.description != null)
                  _buildDetailRow('Description', transaction.description!),
                if (transaction.fee != null)
                  _buildDetailRow(
                      'Fee', 'TZS ${transaction.fee!.toStringAsFixed(0)}'),
                if (transaction.netAmount != null)
                  _buildDetailRow('Net Amount',
                      'TZS ${transaction.netAmount!.toStringAsFixed(0)}'),

                const SizedBox(height: AppConstants.padL),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.padS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
