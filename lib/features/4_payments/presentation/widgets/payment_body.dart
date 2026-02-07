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

  PaymentMethod _selectedMethod = PaymentMethod.payByLink;
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
        _handlePayByLink();
        break;
      case PaymentMethod.ussdPush:
        _handleUssdPush();
        break;
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

  // ============================================================================
// 🔥 PAYMENT_BODY.DART - REQUIRED CHANGES
// ============================================================================
//
// You need to update TWO methods in your payment_body.dart file:
//
// 1. _handlePayByLink() - Add userId parameter
// 2. _handleUssdPush() - Add userId parameter
//
// ============================================================================

// ============================================================================
// CHANGE 1: Update _handlePayByLink() method (around line 179-242)
// ============================================================================

  Future<void> _handlePayByLink() async {
    if (!_formKey.currentState!.validate()) return;
    widget.onPaymentStarted();

    try {
      final fullNumber = _getFormattedPhoneNumber();
      final paymentService = sl<PaymentService>();

      // 🔥 FIX: Get userId from AuthBloc
      final authState = context.read<AuthBloc>().state;
      final userId = authState is Authenticated ? authState.user.uid : null;

      final paymentLink = await paymentService.createPaymentLink(
        orderId: widget.args.appointmentId,
        amount: widget.args.amount,
        name: widget.args.customerName,
        email: widget.args.customerEmail,
        phone: fullNumber,
        userId: userId, // 🔥 NEW: Pass userId for transaction tracking
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
          widget.onPaymentEnded();
          CustomSnackBar.show(
            context,
            message: 'Payment verification pending. Please wait for confirmation.',
            type: SnackBarType.warning,
          );
        }
      } else {
        widget.onPaymentEnded();
      }
    } catch (e, stackTrace) {
      log.e('Pay by Link error', error: e, stackTrace: stackTrace);
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


// ============================================================================
// CHANGE 2: Update _handleUssdPush() method (around line 244-272)
// ============================================================================

  Future<void> _handleUssdPush() async {
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
      log.e('USSD Push error', error: e, stackTrace: stackTrace);
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
            Text(
              'Select Payment Method',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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

            // Continue button
            PrimaryGradientButton(
              text: 'Continue to Payment',
              isLoading: widget.isProcessingPayment,
              onPressed: widget.isProcessingPayment ? null : _handleContinue,
              iconData: Icons.arrow_forward,
            ),
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

            // Pay by Link
            PaymentMethodOption(
              method: PaymentMethod.payByLink,
              isSelected: _selectedMethod == PaymentMethod.payByLink,
              badge: (walletState is! WalletLoaded || !canUseWallet)
                  ? 'RECOMMENDED'
                  : null,
              badgeColor: Colors.blue,
              onTap: () => setState(() => _selectedMethod = PaymentMethod.payByLink),
            ),
            const SizedBox(height: AppConstants.padM),

            // USSD Push
            PaymentMethodOption(
              method: PaymentMethod.ussdPush,
              isSelected: _selectedMethod == PaymentMethod.ussdPush,
              onTap: () => setState(() => _selectedMethod = PaymentMethod.ussdPush),
            ),
          ],
        );
      },
    );
  }
}