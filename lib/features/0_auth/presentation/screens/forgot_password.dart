import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/services/service_locator.dart';
import '../../../../app/utils/validators.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../shared/widgets/text_form_field.dart';
import '../../domain/repositories/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Helper method to show a snackbar
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  /// NEW: Method now calls the repository directly.
  Future<void> _sendResetLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await sl<AuthRepository>().sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      // On success, show confirmation and pop the screen.
      _showSnackBar('Password reset link sent! Check your email.');
      if (mounted) context.pop();
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
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
                  Text('Forgot Password?',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium),
                  const SizedBox(height: AppConstants.padS),
                  Text(
                    'No worries! Enter your email and we will send you a reset link.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(178)),
                  ),
                  const SizedBox(height: AppConstants.padXXL),
                  CustomTextFormField(
                    controller: _emailController,
                    labelText: 'Email Address',
                    hintText: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: AppValidators.email,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: AppConstants.padXL),
                  PrimaryGradientButton(
                    text: 'SEND RESET LINK',
                    onPressed: _isLoading ? null : _sendResetLink,
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
