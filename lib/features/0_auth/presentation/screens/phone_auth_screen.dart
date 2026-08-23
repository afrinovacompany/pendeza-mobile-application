import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_router.dart';
import '../../../../shared/widgets/phone_number_input_field.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../auth_navigation.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_chrome.dart';

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
          // Only push OTP from this screen. Resend from OtpScreen also emits
          // PhoneVerificationCodeSent and must not stack another OTP route.
          final currentPath = GoRouterState.of(context).uri.path;
          if (currentPath == AppRoutes.phoneAuth) {
            context.push(AppRoutes.otp, extra: {
              'sessionId': state.sessionId,
              'phoneNumber': state.phoneNumber,
            });
          }
        } else if (state is AuthError) {
          final currentPath = GoRouterState.of(context).uri.path;
          if (currentPath == AppRoutes.phoneAuth) {
            _showErrorSnackBar(state.message);
          }
        } else if (state is RoleSelectionRequired) {
          context.go(AppRoutes.roleSelection);
        } else if (state is ClientProfileSetupRequired) {
          context.go(AppRoutes.clientSetup);
        } else if (state is OwnerProfileSetupRequired) {
          context.go(AppRoutes.ownerSetup);
        } else if (state is Authenticated) {
          goAfterAuthenticated(context, state);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return AuthScaffold(
            isLoading: isLoading,
            loadingMessage: 'auth.phone.sending'.tr(),
            body: AuthPageBody(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(
                      title: 'auth.phone.title'.tr(),
                      subtitle: 'auth.phone.description'.tr(),
                      leading: Icon(
                        Icons.phone_android_rounded,
                        size: AuthChrome.iconSize,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AuthChrome.headerGap),

                    PhoneNumberInputField(
                      controller: _phoneController,
                      onCountryChanged: (country) {
                        setState(() {
                          _countryCode = country.dialCode ?? '+255';
                        });
                      },
                    ),
                    const SizedBox(height: AuthChrome.headerGap),

                    PrimaryGradientButton(
                      text: 'auth.phone.button'.tr(),
                      onPressed: isLoading ? null : _sendOtp,
                      isLoading: isLoading,
                      height: AuthChrome.ctaHeight,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}