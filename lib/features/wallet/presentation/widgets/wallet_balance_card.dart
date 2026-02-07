import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_event.dart';

/// Compact Wallet Balance Card for Dashboard Header
///
/// Shows:
/// - Current balance (for authenticated users)
/// - "Sign in to use Wallet" prompt (for guests)
/// - Top Up button
/// - Quick access to full wallet screen
class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // === GUEST MODE ===
        if (authState is GuestMode) {
          return _buildGuestWalletCard(context, theme);
        }

        // === AUTHENTICATED USER ===
        if (authState is Authenticated) {
          return BlocProvider(
            create: (context) => WalletBloc(
              walletRepository: context.read(),
              paymentService: context.read(),
            )..add(LoadWallet(authState.user.uid)),
            child: _buildAuthenticatedWalletCard(context, theme, authState.user.uid),
          );
        }

        // Loading state
        return const SizedBox.shrink();
      },
    );
  }

  /// Guest Mode: Show "Sign in to use Wallet" prompt
  Widget _buildGuestWalletCard(BuildContext context, ThemeData theme) {
    return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.padL,
          vertical: AppConstants.padS,
        ),
        padding: const EdgeInsets.all(AppConstants.padL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.08),
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Wallet Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.creditcard_fill,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),

            const SizedBox(width: AppConstants.padM),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sign in to use wallet features',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Sign In Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(AppRoutes.login),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Sign In',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  /// Authenticated User: Show balance and actions
  Widget _buildAuthenticatedWalletCard(
      BuildContext context,
      ThemeData theme,
      String userId,
      ) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, walletState) {
        // Extract balance
        double balance = 0.0;
        bool isLoading = false;

        if (walletState is WalletLoading) {
          isLoading = true;
        } else if (walletState is WalletLoaded) {
          balance = walletState.wallet.balance;
        } else if (walletState is WalletDepositSuccess ||
            walletState is WalletPaymentSuccess) {
          // Show updated balance after successful operations
          if (walletState is WalletDepositSuccess) {
            balance = walletState.wallet.balance;
          } else if (walletState is WalletPaymentSuccess) {
            balance = walletState.wallet.balance;
          }
        }

        return GestureDetector(
          onTap: () => context.push(AppRoutes.clientWallet),
          child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.padL,
                vertical: AppConstants.padS,
              ),
              padding: const EdgeInsets.all(AppConstants.padL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.12),
                    theme.colorScheme.secondary.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Wallet Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.creditcard_fill,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: AppConstants.padM),

                  // Balance Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wallet Balance',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isLoading)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          TweenAnimationBuilder<double>(
                            key: ValueKey(balance),
                            tween: Tween(begin: 0.0, end: balance),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Text(
                                'TZS ${value.toStringAsFixed(0)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  // Top Up Button
                  // ✅ FIXED: Navigate to wallet screen which handles deposit
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Navigate to the wallet screen
                        // The wallet screen already has deposit logic
                        context.push(AppRoutes.clientWallet);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.add_circled_solid,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Top Up',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        );
      },
    );
  }
}