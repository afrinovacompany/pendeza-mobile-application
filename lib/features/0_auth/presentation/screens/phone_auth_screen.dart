import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_router.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/phone_number_input_field.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _countryCode = '+255'; // Default to Tanzania

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // 🔥 NEW: Use BLoC event instead of direct Firebase call
  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      final phoneNumber = _countryCode + _phoneController.text.trim();

      // Dispatch event to BLoC
      context.read<AuthBloc>().add(PhoneSignInRequested(phoneNumber));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // 🔥 NEW: Handle phone verification code sent state
        if (state is PhoneVerificationCodeSent) {
          // Navigate to OTP screen
          context.push(AppRoutes.otp, extra: {
            'verificationId': state.verificationId,
            'phoneNumber': state.phoneNumber,
          });
        } else if (state is AuthError) {
          _showErrorSnackBar(state.message);
        } else if (state is RoleSelectionRequired) {
          context.go(AppRoutes.roleSelection);
        } else if (state is Authenticated) {
          final role = state.user.role;
          if (role == 'owner') {
            context.go(AppRoutes.ownerHome);
          } else {
            context.go(AppRoutes.clientHome);
          }
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
            ),
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConstants.padL),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              Icons.phone_android_rounded,
                              size: 80,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: AppConstants.padL),
                            Text('auth.phone.title'.tr(),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displayMedium),
                            const SizedBox(height: AppConstants.padS),
                            Text(
                              'auth.phone.description'.tr(),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(178),
                              ),
                            ),
                            const SizedBox(height: AppConstants.padXXL),

                            PhoneNumberInputField(
                              controller: _phoneController,
                              onCountryChanged: (country) {
                                setState(() {
                                  _countryCode = country.dialCode ?? '+255';
                                });
                              },
                            ),
                            const SizedBox(height: AppConstants.padXXL),

                            PrimaryGradientButton(
                              text: 'auth.phone.button'.tr(),
                              onPressed: isLoading ? null : _sendOtp,
                              isLoading: isLoading,
                            ),

                            const SizedBox(height: AppConstants.padL),

                            // Helper text
                            Text(
                              'We\'ll send you a 6-digit verification code',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(153),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Loading overlay
                  if (isLoading)
                    Container(
                      color: Colors.black26,
                      child: Center(
                        child: Card(
                          elevation: 8,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  'Sending verification code...',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}