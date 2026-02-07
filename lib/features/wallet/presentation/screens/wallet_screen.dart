import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:pendeza/features/wallet/presentation/widgets/deposit_bottom_sheet.dart'; // ✅ ADD THIS IMPORT
import 'package:pendeza/shared/models/transaction_model.dart';
import 'package:pendeza/shared/widgets/custom_snackbar.dart';

/// Full Wallet Screen
///
/// Shows:
/// - Large balance display
/// - Quick action buttons (Top Up, Send, History)
/// - Recent transactions
/// - Pull to refresh
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    if (authState is! Authenticated) {
      // Redirect guests to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userId = authState.user.uid;

    return BlocProvider(
      create: (context) => WalletBloc(
        walletRepository: context.read(),
        paymentService: context.read(),
      )..add(LoadWallet(userId)),
      child: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is WalletDepositSuccess) {
            CustomSnackBar.show(
              context,
              message: state.message,
              type: SnackBarType.success,
            );
          } else if (state is WalletDepositPending) {
            // ✅ Show info when deposit is pending
            CustomSnackBar.show(
              context,
              message: state.message,
              type: SnackBarType.info,
              duration: const Duration(seconds: 5),
            );
          } else if (state is WalletError) {
            CustomSnackBar.show(
              context,
              message: state.message,
              type: SnackBarType.error,
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Wallet'),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () => context.push('/client/wallet/history'),
                  icon: const Icon(CupertinoIcons.list_bullet),
                  tooltip: 'Transaction History',
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<WalletBloc>().add(RefreshWallet(userId));
                await Future.delayed(const Duration(seconds: 1));
              },
              child: _buildBody(context, state, userId),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, WalletState state, String userId) {
    if (state is WalletLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is WalletError && state.wallet == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 60),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<WalletBloc>().add(LoadWallet(userId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Extract wallet data from various states
    final wallet = _extractWallet(state);
    final transactions = (state is WalletLoaded)
        ? state.recentTransactions
        : <TransactionModel>[];

    if (wallet == null) {
      return const Center(child: Text('Unable to load wallet'));
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: AppConstants.padL),

          // Balance Display
          _buildBalanceCard(context, wallet.balance, state),

          const SizedBox(height: AppConstants.padL),

          // Quick Actions
          _buildQuickActions(context, userId),

          const SizedBox(height: AppConstants.padXL),

          // Recent Transactions
          _buildRecentTransactions(context, transactions),

          const SizedBox(height: AppConstants.padXL),
        ],
      ),
    );
  }

  /// Extract wallet from various states
  dynamic _extractWallet(WalletState state) {
    if (state is WalletLoaded) return state.wallet;
    if (state is WalletDepositSuccess) return state.wallet;
    if (state is WalletDepositPending) return state.wallet;
    if (state is WalletDepositInitiating) return state.wallet;
    if (state is WalletPaymentSuccess) return state.wallet;
    if (state is WalletPaymentProcessing) return state.wallet;
    if (state is WalletInsufficientBalance) return state.wallet;
    if (state is WalletError) return state.wallet;
    return null;
  }

  /// Large Balance Display Card
  Widget _buildBalanceCard(BuildContext context, double balance, WalletState state) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
      padding: const EdgeInsets.all(AppConstants.padXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Text(
            'Available Balance',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: AppConstants.padM),

          // Balance Amount
          TweenAnimationBuilder<double>(
            key: ValueKey(balance),
            tween: Tween(begin: 0.0, end: balance),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                'TZS ${value.toStringAsFixed(0)}',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              );
            },
          ),

          const SizedBox(height: AppConstants.padS),

          // Status indicator for pending deposits
          if (state is WalletDepositPending)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Processing deposit...',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Status indicator when initiating deposit
          if (state is WalletDepositInitiating)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Initiating payment...',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Quick Action Buttons
  Widget _buildQuickActions(BuildContext context, String userId) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context,
              icon: CupertinoIcons.add_circled_solid,
              label: 'Top Up',
              color: theme.colorScheme.primary,
              onTap: () => _showDepositBottomSheet(context, userId),
            ),
          ),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: _buildActionButton(
              context,
              icon: CupertinoIcons.arrow_right_arrow_left_circle_fill,
              label: 'History',
              color: theme.colorScheme.secondary,
              onTap: () => context.push('/client/wallet/history'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.padL),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: AppConstants.padS),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Recent Transactions Section
  Widget _buildRecentTransactions(
      BuildContext context,
      List<TransactionModel> transactions,
      ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (transactions.isNotEmpty)
                TextButton(
                  onPressed: () => context.push('/client/wallet/history'),
                  child: const Text('View All'),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppConstants.padM),

        if (transactions.isEmpty)
          _buildEmptyTransactions(theme)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length > 5 ? 5 : transactions.length,
            itemBuilder: (context, index) {
              return _buildTransactionTile(context, transactions[index]);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyTransactions(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
      padding: const EdgeInsets.all(AppConstants.padXL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.doc_text,
            size: 60,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppConstants.padM),
          Text(
            'No transactions yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.padS),
          Text(
            'Your transaction history will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, TransactionModel transaction) {
    final theme = Theme.of(context);

    // Determine icon and color based on type
    IconData icon;
    Color iconColor;

    switch (transaction.type) {
      case TransactionType.deposit:
        icon = CupertinoIcons.arrow_down_circle_fill;
        iconColor = Colors.green;
        break;
      case TransactionType.payment:
        icon = CupertinoIcons.arrow_up_circle_fill;
        iconColor = Colors.red;
        break;
      case TransactionType.refund:
        icon = CupertinoIcons.arrow_counterclockwise_circle_fill;
        iconColor = Colors.blue;
        break;
      default:
        icon = CupertinoIcons.arrow_right_arrow_left_circle;
        iconColor = theme.colorScheme.primary;
    }

    final isCredit = transaction.type == TransactionType.deposit ||
        transaction.type == TransactionType.refund;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.padL,
        vertical: AppConstants.padXS,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          transaction.typeLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM d, yyyy • h:mm a').format(transaction.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Text(
          '${isCredit ? '+' : '-'} ${transaction.formattedAmount}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isCredit ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  // ✅ FIXED: Show the actual deposit bottom sheet
  void _showDepositBottomSheet(BuildContext context, String userId) {
    // Get the WalletBloc from the current context so the bottom sheet
    // can dispatch events to the same bloc instance
    final walletBloc = context.read<WalletBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        // Provide the same WalletBloc to the bottom sheet
        return BlocProvider.value(
          value: walletBloc,
          child: DepositBottomSheet(userId: userId),
        );
      },
    );
  }
}