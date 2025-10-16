import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

// --- Adjust these import paths to match your project structure ---
import 'package:go_router/go_router.dart';

import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/services/service_locator.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../domain/repositories/auth_repository.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Local loading state

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // Helper method to show a snackbar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// NEW: Verify OTP method calls the repository directly.
  Future<void> _verifyOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await sl<AuthRepository>().verifyOtp(
        verificationId: widget.verificationId,
        smsCode: _otpController.text,
      );
      // On success, the AuthBloc listener in the router will handle navigation.
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
        isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: theme.textTheme.headlineMedium,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppConstants.radiusM,
        border: Border.all(color: theme.dividerColor),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: theme.colorScheme.onSurface,
          onPressed: _isLoading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.padL),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Verify Code',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium),
                  const SizedBox(height: AppConstants.padS),
                  Text(
                    'Enter the 6-digit code sent to\n${widget.phoneNumber}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(178),
                    ),
                  ),
                  const SizedBox(height: AppConstants.padXXL),
                  Pinput(
                    controller: _otpController,
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(
                            color: theme.colorScheme.primary, width: 2),
                      ),
                    ),
                    submittedPinTheme: defaultPinTheme,
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    showCursor: true,
                    enabled: !_isLoading,
                    onCompleted: (pin) => _verifyOtp(),
                    validator: (s) {
                      return s?.length == 6 ? null : 'Pin is incomplete';
                    },
                  ),
                  const SizedBox(height: AppConstants.padXL),
                  PrimaryGradientButton(
                    text: 'VERIFY',
                    onPressed: _isLoading ? null : _verifyOtp,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppConstants.padL),
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      // TODO: Implement resend OTP logic by calling repository
                    },
                    child: Text(
                      'Didn\'t receive the code? Resend',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


