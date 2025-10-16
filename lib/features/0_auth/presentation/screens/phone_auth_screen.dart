import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_router.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/services/service_locator.dart';
import '../../../../shared/widgets/phone_number_input_field.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../domain/repositories/auth_repository.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _countryCode = '+255'; // Default to Tanzania
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
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

  /// NEW: Method now calls the repository directly and handles callbacks.
  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    final completer = Completer<void>();
    final fullPhoneNumber = '$_countryCode${_phoneController.text.trim()}';

    try {
      await sl<AuthRepository>().signInWithPhone(
        phoneNumber: fullPhoneNumber,
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          // On success, navigate to the OTP screen with the real data
          context.push(
            AppRoutes.otp,
            extra: {
              'verificationId': verificationId,
              'phoneNumber': fullPhoneNumber,
            },
          );
          if (!completer.isCompleted) completer.complete();
        },
        verificationFailed: (FirebaseAuthException e) {
          // On failure, show an error and complete the process
          _showErrorSnackBar(e.message ?? 'Phone verification failed.');
          if (!completer.isCompleted) completer.complete();
        },
      );
      // Wait for one of the callbacks to fire before continuing.
      await completer.future;
    } catch (e) {
      _showErrorSnackBar(e.toString());
      if (!completer.isCompleted) completer.complete();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  Text('Enter Your Phone Number',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium),
                  const SizedBox(height: AppConstants.padS),
                  Text(
                    'We will send you a 6-digit verification code.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(178),
                    ),
                  ),
                  const SizedBox(height: AppConstants.padXL),
                  PhoneNumberInputField(
                    controller: _phoneController,
                    onCountryChanged: (country) {
                      setState(() {
                        _countryCode = country.dialCode ?? '+255';
                      });
                    },
                  ),
                  const SizedBox(height: AppConstants.padXL),
                  PrimaryGradientButton(
                    text: 'SEND CODE',
                    onPressed: _isLoading ? null : _sendOtp,
                    isLoading: _isLoading,
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
