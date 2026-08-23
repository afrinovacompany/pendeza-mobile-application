import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_event.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:pendeza/shared/widgets/phone_number_input_field.dart';
import 'package:pendeza/shared/widgets/custom_snackbar.dart';

/// Bottom Sheet for depositing money to wallet
///
/// Features:
/// - Quick amount selection (5k, 10k, 20k, 50k)
/// - Custom amount input
/// - Phone number input with country code picker (matches PaymentScreen)
/// - Supports all mobile money providers (M-Pesa, Airtel Money, Tigo Pesa, Halotel)
/// - Auto-fills user's phone number
/// - Real-time validation
class DepositBottomSheet extends StatefulWidget {
  final String userId;

  const DepositBottomSheet({
    super.key,
    required this.userId,
  });

  @override
  State<DepositBottomSheet> createState() => _DepositBottomSheetState();
}

class _DepositBottomSheetState extends State<DepositBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();

  // Country code for phone number (default: Tanzania +255)
  CountryCode _selectedCountryCode = CountryCode(
    name: 'Tanzania',
    code: 'TZ',
    dialCode: '+255',
  );

  // Quick amount options
  final List<double> _quickAmounts = [5000, 10000, 20000, 50000];
  double? _selectedAmount;

  bool _isProcessing = false;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _loadUserPhoneNumber();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Load and pre-fill user's phone number (same logic as PaymentScreen)
  Future<void> _loadUserPhoneNumber() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final user = authState.user;
        if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
          String phone = user.phoneNumber!;

          // Remove leading + if present
          if (phone.startsWith('+')) {
            phone = phone.substring(1);
          }

          // Handle different phone formats
          if (phone.startsWith('255')) {
            // Phone has country code: +255712345678 or 255712345678
            _selectedCountryCode = CountryCode(
              name: 'Tanzania',
              code: 'TZ',
              dialCode: '+255',
            );
            // Extract local number (9 digits after country code)
            final localNumber = phone.substring(3);
            _phoneController.text = localNumber;
          } else if (phone.startsWith('0')) {
            // Phone starts with 0: 0712345678
            _phoneController.text = phone.substring(1);
          } else {
            // Just the local number: 712345678
            _phoneController.text = phone;
          }

          log.d('📱 Pre-filled phone number: ${_phoneController.text}');
        }
      }
    } catch (e, s) {
      log.e('Error loading user phone number', error: e, stackTrace: s);
    } finally {
      if (mounted) {
        setState(() => _isLoadingUserData = false);
      }
    }
  }

  /// Format phone number for API (same as PaymentScreen)
  String _getFormattedPhoneNumber() {
    String dialCode = _selectedCountryCode.dialCode?.replaceAll('+', '') ?? '255';
    String number = _phoneController.text.trim();

    // Remove leading 0 if present
    if (number.startsWith('0')) {
      number = number.substring(1);
    }

    return "$dialCode$number";
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  void _initiateDeposit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 1000) {
      CustomSnackBar.show(
        context,
        message: 'Minimum deposit is TZS 1,000',
        type: SnackBarType.error,
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    setState(() => _isProcessing = true);

    // Get formatted phone number
    final formattedPhone = _getFormattedPhoneNumber();
    log.i('💳 Initiating deposit: TZS $amount to phone $formattedPhone');

    // Trigger deposit via WalletBloc
    context.read<WalletBloc>().add(
      InitiateDeposit(
        userId: widget.userId,
        amount: amount,
        phoneNumber: formattedPhone,
        userName: authState.user.fullName,
        userEmail: authState.user.email,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        // New reactive states
        if (state is DepositInProgress) {
          setState(() => _isProcessing = false);
          Navigator.pop(context); // Close bottom sheet
          CustomSnackBar.show(
            context,
            message: state.message,
            type: SnackBarType.info,
            duration: const Duration(seconds: 5),
          );
        } else if (state is DepositSuccess) {
          setState(() => _isProcessing = false);
          Navigator.pop(context); // Close bottom sheet if still open
          CustomSnackBar.show(
            context,
            message: state.message,
            type: SnackBarType.success,
          );
        } else if (state is DepositError) {
          setState(() => _isProcessing = false);
          CustomSnackBar.show(
            context,
            message: state.message,
            type: SnackBarType.error,
          );
        } else if (state is WalletError) {
          setState(() => _isProcessing = false);
          CustomSnackBar.show(
            context,
            message: state.message,
            type: SnackBarType.error,
          );
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          top: AppConstants.padL,
          left: AppConstants.padL,
          right: AppConstants.padL,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppConstants.padL,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
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

                // Title
                Text(
                  'Top Up Wallet',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppConstants.padS),

                // ✅ FIXED: Provider-agnostic subtitle
                Text(
                  'Add money to your Pendeza Wallet',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppConstants.padXL),

                // Quick Amount Selection
                Text(
                  'Quick Select',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: AppConstants.padM),

                Wrap(
                  spacing: AppConstants.padM,
                  runSpacing: AppConstants.padM,
                  children: _quickAmounts.map((amount) {
                    final isSelected = _selectedAmount == amount;
                    return _buildQuickAmountChip(context, amount, isSelected);
                  }).toList(),
                ),

                const SizedBox(height: AppConstants.padXL),

                // Custom Amount Input
                Text(
                  'Or Enter Amount',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: AppConstants.padM),

                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount (TZS)',
                    hintText: '10000',
                    prefixIcon: Icon(
                      CupertinoIcons.money_dollar_circle,
                      color: theme.colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount < 1000) {
                      return 'Minimum amount is TZS 1,000';
                    }
                    if (amount > 5000000) {
                      return 'Maximum amount is TZS 5,000,000';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Clear quick selection when typing custom amount
                    if (_selectedAmount != null) {
                      setState(() => _selectedAmount = null);
                    }
                  },
                ),

                const SizedBox(height: AppConstants.padL),

                // Phone Number Input Section
                Text(
                  'Mobile Money Number',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: AppConstants.padM),

                // ✅ FIXED: Use PhoneNumberInputField with country picker
                if (_isLoadingUserData)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  PhoneNumberInputField(
                    controller: _phoneController,
                    onCountryChanged: (countryCode) {
                      setState(() {
                        _selectedCountryCode = countryCode;
                      });
                    },
                    initialCountryCode: _selectedCountryCode.code,
                    labelText: 'Phone Number',
                    hintText: '712345678',
                    enabled: !_isProcessing,
                  ),

                const SizedBox(height: AppConstants.padXL),

                // Submit Button
                ElevatedButton(
                  onPressed: (_isProcessing || _isLoadingUserData)
                      ? null
                      : _initiateDeposit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.padL,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : Text(
                    'Proceed to Payment',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.padM),

                // ✅ FIXED: Provider-agnostic info text
                Container(
                  padding: const EdgeInsets.all(AppConstants.padM),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppConstants.padM),
                      Expanded(
                        child: Text(
                          'You will receive a payment prompt on your phone to complete the transaction',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Supported providers hint
                const SizedBox(height: AppConstants.padS),
                Text(
                  'Supports M-Pesa, Airtel Money, Tigo Pesa & Halotel',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(
      BuildContext context,
      double amount,
      bool isSelected,
      ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _selectQuickAmount(amount),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          )
              : null,
          color: isSelected ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : theme.dividerColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Text(
          'TZS ${_formatAmount(amount)}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// Format amount with thousand separators for display
  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

/// Helper function to show deposit bottom sheet
///
/// Usage:
/// ```dart
/// showDepositBottomSheet(context, userId);
/// ```
void showDepositBottomSheet(BuildContext context, String userId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DepositBottomSheet(userId: userId),
  );
}