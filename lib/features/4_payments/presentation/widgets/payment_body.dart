// =============================================================================
// Payment Body Widget
// =============================================================================
// The main content body of the payment screen, handling:
// - Loading user data
// - Payment method selection
// - Payment initiation
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_code_picker/country_code_picker.dart';

import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/app/services/payment_service.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/shared/widgets/primary_gradient_button.dart';
import 'package:pendeza/shared/widgets/phone_number_input_field.dart';
import 'package:pendeza/shared/widgets/custom_snackbar.dart';

// Wallet imports
import 'package:pendeza/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_state.dart';

// Payment module imports
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../models/payment_arguments.dart';
import '../models/payment_method.dart';
import '../screens/payment_webview_screen.dart';
import 'payment_amount_card.dart';
import 'payment_method_option.dart';
import 'payment_info_card.dart';
import 'wallet_balance_card.dart';
import 'payment_waiting_dialog.dart';

class PaymentBody extends StatefulWidget {
  final PaymentArguments args;
  final bool isProcessingPayment;
  final VoidCallback onPaymentStarted;
  final VoidCallback onPaymentEnded;
  final VoidCallback onPaymentSuccess;
  final void Function(String message) onPaymentFailure;

  const PaymentBody({
    super.key,
    required this.args,
    required this.isProcessingPayment,
    required this.onPaymentStarted,
    required this.onPaymentEnded,
    required this.onPaymentSuccess,
    required this.onPaymentFailure,
  });

  @override
  State<PaymentBody> createState() => _PaymentBodyState();
}

class _PaymentBodyState extends State<PaymentBody> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  PaymentMethod _selectedMethod = PaymentMethod.mobileMoney;
  CountryCode _selectedCountryCode = CountryCode(
    name: 'Tanzania',
    code: 'TZ',
    dialCode: '+255',
  );

  bool _isLoadingUserData = true;
  bool _isLoadingWallet = true;

  @override
  void initState() {
    super.initState();
    _loadUserPhoneNumber();
    _loadWalletBalance();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  Future<void> _loadWalletBalance() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        context.read<WalletBloc>().add(LoadWallet(authState.user.uid));
      }
    } catch (e, s) {
      log.e('Error loading wallet balance', error: e, stackTrace: s);
    } finally {
      if (mounted) setState(() => _isLoadingWallet = false);
    }
  }

  Future<void> _loadUserPhoneNumber() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final user = authState.user;
        if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
          String phone = user.phoneNumber!;
          if (phone.startsWith('+')) phone = phone.substring(1);

          if (phone.startsWith('255')) {
            _selectedCountryCode = CountryCode(
              name: 'Tanzania',
              code: 'TZ',
              dialCode: '+255',
            );
            final localNumber = phone.substring(3);
            _phoneController.text = localNumber;
          } else if (phone.startsWith('0')) {
            _phoneController.text = phone.substring(1);
          } else {
            _phoneController.text = phone;
          }
        }
      }
    } catch (e, s) {
      log.e('Error loading user phone number', error: e, stackTrace: s);
    } finally {
      if (mounted) setState(() => _isLoadingUserData = false);
    }
  }

  // ============================================================
  // PAYMENT HANDLERS
  // ============================================================

  String _getFormattedPhoneNumber() {
    String dialCode = _selectedCountryCode.dialCode?.replaceAll('+', '') ?? '255';
    String number = _phoneController.text.trim();
    if (number.startsWith('0')) number = number.substring(1);
    return "$dialCode$number";
  }

  void _handleContinue() {
    switch (_selectedMethod) {
      case PaymentMethod.wallet:
        _handleWalletPayment();
        break;
      case PaymentMethod.payByLink:
        _handlePayByCard();
        break;
      case PaymentMethod.mobileMoney:
        _handleMobilePayment();
    }
  }

  Future<void> _handleWalletPayment() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    widget.onPaymentStarted();

    context.read<WalletBloc>().add(PayFromWallet(
      userId: authState.user.uid,
      salonOwnerId: widget.args.salonOwnerId ?? 'UNKNOWN_OWNER',
      appointmentId: widget.args.appointmentId,
      amount: widget.args.amount,
      description: 'Booking payment',
    ));
  }

  Future<void> _handlePayByCard() async {
    if (!_formKey.currentState!.validate()) return;
    widget.onPaymentStarted();

    try {
      final fullNumber     = _getFormattedPhoneNumber();
      final paymentService = sl<PaymentService>();
      final authState      = context.read<AuthBloc>().state;
      final userId         = authState is Authenticated ? authState.user.uid : null;

      final paymentLink = await paymentService.createPaymentLink(
        orderId: widget.args.appointmentId,
        amount:  widget.args.amount,
        name:    widget.args.customerName,
        email:   widget.args.customerEmail,
        phone:   fullNumber,
        userId:  userId,
      );

      if (!mounted) return;

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(
            paymentUrl: paymentLink,
            title: 'Complete Payment',
          ),
        ),
      );

      if (!mounted) return;

      if (result == true) {
        // Check Firestore — Snippe webhook may have already fired while WebView was open
        CustomSnackBar.show(
          context,
          message: 'Verifying payment...',
          type: SnackBarType.info,
        );
        final isConfirmed = await paymentService.verifyTransaction(
          widget.args.appointmentId,
        );
        if (!mounted) return;
        if (isConfirmed) {
          widget.onPaymentSuccess();
        } else {
          // Webhook hasn't fired yet — PaymentScreen's Firestore listener will catch it
          widget.onPaymentEnded();
          CustomSnackBar.show(
            context,
            message: 'Payment submitted. Waiting for confirmation...',
            type: SnackBarType.info,
          );
        }
      } else {
        widget.onPaymentEnded();
      }
    } catch (e, stackTrace) {
      log.e('Pay by Card error', error: e, stackTrace: stackTrace);
      widget.onPaymentEnded();
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Failed to initiate payment. Please try again.',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _handleMobilePayment() async {
    if (!_formKey.currentState!.validate()) return;

    // 🔥 FIX: Get userId from AuthBloc BEFORE starting payment
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      CustomSnackBar.show(
        context,
        message: 'Please log in to continue',
        type: SnackBarType.error,
      );
      return;
    }

    widget.onPaymentStarted();

    try {
      final fullNumber = _getFormattedPhoneNumber();

      // 🔥 FIX: Pass userId to InitiatePayment event
      context.read<PaymentBloc>().add(InitiatePayment(
        phoneNumber: fullNumber,
        amount: widget.args.amount,
        appointmentId: widget.args.appointmentId,
        customerName: widget.args.customerName,
        customerEmail: widget.args.customerEmail,
        userId: authState.user.uid, // 🔥 CRITICAL: Must pass userId
      ));

      showPaymentWaitingDialog(context);
    } catch (e, stackTrace) {
      log.e('Mobile payment error', error: e, stackTrace: stackTrace);
      widget.onPaymentEnded();
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Failed to initiate payment. Please try again.',
          type: SnackBarType.error,
        );
      }
    }
  }
  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingUserData || _isLoadingWallet) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.padL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount card
            PaymentAmountCard(amount: widget.args.amount),
            const SizedBox(height: AppConstants.padXL),

            // Wallet balance card
            BlocBuilder<WalletBloc, WalletState>(
              builder: (context, walletState) {
                if (walletState is WalletLoaded) {
                  return WalletBalanceCard(
                    wallet: walletState.wallet,
                    requiredAmount: widget.args.amount,
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: AppConstants.padL),

            // Section title
            Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Select Payment Method',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.padM),

            // Payment method selector
            _buildPaymentMethodSelector(theme),

            const SizedBox(height: AppConstants.padL),

            // Phone input (only for non-wallet methods)
            if (_selectedMethod.requiresPhoneNumber)
              PhoneNumberInputField(
                controller: _phoneController,
                initialCountryCode: _selectedCountryCode.code,
                onCountryChanged: (code) {
                  setState(() => _selectedCountryCode = code);
                },
              ),

            const SizedBox(height: AppConstants.padL),

            // Info card
            PaymentInfoCard(selectedMethod: _selectedMethod),

            const SizedBox(height: AppConstants.padXL),

            // Secure payment note
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  'Secured by Snippe',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.padM),

            // Continue button
            PrimaryGradientButton(
              text: 'Pay Now',
              isLoading: widget.isProcessingPayment,
              onPressed: widget.isProcessingPayment ? null : _handleContinue,
              iconData: Icons.arrow_forward_rounded,
            ),

            const SizedBox(height: AppConstants.padM),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector(ThemeData theme) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, walletState) {
        final canUseWallet = walletState is WalletLoaded &&
            walletState.wallet.balance >= widget.args.amount;

        return Column(
          children: [
            // Wallet option (only if wallet is loaded)
            if (walletState is WalletLoaded) ...[
              PaymentMethodOption(
                method: PaymentMethod.wallet,
                isSelected: _selectedMethod == PaymentMethod.wallet,
                isDisabled: !canUseWallet,
                badge: canUseWallet ? 'INSTANT' : null,
                badgeColor: Colors.green,
                customSubtitle: canUseWallet
                    ? 'Instant payment (Recommended) ⚡'
                    : 'Insufficient balance',
                onTap: canUseWallet
                    ? () => setState(() => _selectedMethod = PaymentMethod.wallet)
                    : null,
              ),
              const SizedBox(height: AppConstants.padM),
            ],

            // USSD Push
            PaymentMethodOption(
              method: PaymentMethod.mobileMoney,
              isSelected: _selectedMethod == PaymentMethod.mobileMoney,
              onTap: () => setState(() => _selectedMethod = PaymentMethod.mobileMoney),
            ),
            const SizedBox(height: AppConstants.padM),

            // Pay by Card (last priority, no badge)
            PaymentMethodOption(
              method: PaymentMethod.payByLink,
              isSelected: _selectedMethod == PaymentMethod.payByLink,
              onTap: () => setState(() => _selectedMethod = PaymentMethod.payByLink),
            ),
          ],
        );
      },
    );
  }
}