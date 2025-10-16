import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_router.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/services/service_locator.dart';
import '../../../../app/utils/validators.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../shared/widgets/secondary_button.dart';
import '../../../../shared/widgets/text_form_field.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _signInWithEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await sl<AuthRepository>().signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // AuthBloc handles state changes, no need for local loading
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await sl<AuthRepository>().signInWithGoogle();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
        isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Determine if we should disable the form
        final isLoading = authState is AuthLoading;

        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                // Main content
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(AppConstants.padL),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(Icons.cut_sharp,
                              size: 80, color: theme.colorScheme.primary),
                          const SizedBox(height: AppConstants.padS),
                          Text('Let\'s Sign You In',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.displayMedium),
                          const SizedBox(height: AppConstants.padXXL),

                          CustomTextFormField(
                            controller: _emailController,
                            labelText: 'Email Address',
                            keyboardType: TextInputType.emailAddress,
                            validator: AppValidators.email,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: AppConstants.padL),

                          CustomTextFormField(
                            controller: _passwordController,
                            labelText: 'Password',
                            obscureText: _isPasswordObscured,
                            validator: (value) => AppValidators.notEmpty(
                                value,
                                message: "Password is required"
                            ),
                            enabled: !isLoading,
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordObscured
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () => setState(
                                      () => _isPasswordObscured = !_isPasswordObscured),
                            ),
                          ),
                          const SizedBox(height: AppConstants.padS),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.push(AppRoutes.forgotPassword),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: AppConstants.padL),

                          PrimaryGradientButton(
                            text: 'SIGN IN',
                            onPressed: isLoading ? null : _signInWithEmail,
                            isLoading: isLoading,
                          ),
                          const SizedBox(height: AppConstants.padXL),

                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppConstants.padS),
                                  child: Text('OR',
                                      style: theme.textTheme.labelMedium)),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: AppConstants.padL),

                          SecondaryButton(
                            text: 'Continue with Google',
                            onPressed: isLoading ? null : _signInWithGoogle,
                          ),
                          const SizedBox(height: AppConstants.padM),

                          SecondaryButton(
                            text: 'Continue with Phone',
                            onPressed: isLoading
                                ? null
                                : () => context.push(AppRoutes.phoneAuth),
                          ),
                          const SizedBox(height: AppConstants.padXL),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account?"),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context.push(AppRoutes.signup),
                                child: const Text('Sign Up'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Optional: Full-screen loading overlay for better UX
                if (isLoading)
                  Container(
                    color: Colors.black12,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Signing in...'),
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
    );
  }
}