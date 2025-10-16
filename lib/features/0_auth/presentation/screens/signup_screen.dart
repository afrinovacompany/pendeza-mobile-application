
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// --- Adjust these import paths to match your project structure ---
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../app/config/app_router.dart';
import '../../../../app/utils/validators.dart';
import '../../../../shared/widgets/text_form_field.dart';
// Import our BLoC



import '../../../../app/services/service_locator.dart';
import '../../domain/repositories/auth_repository.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false; // Local loading state

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  /// NEW: Sign-up method now calls the repository directly.
  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      // Call the repository directly
      await sl<AuthRepository>().signUpWithEmailAndPassword(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
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

    // No BlocListener needed here anymore for auth state changes.
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
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Create Account',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium),
                  Text('Let\'s get you started!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(178))),
                  const SizedBox(height: AppConstants.padXL),

                  CustomTextFormField(
                    controller: _nameController,
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    validator: AppValidators.notEmpty,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: AppConstants.padL),

                  CustomTextFormField(
                    controller: _emailController,
                    labelText: 'Email Address',
                    hintText: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: AppValidators.email,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: AppConstants.padL),

                  CustomTextFormField(
                    controller: _passwordController,
                    labelText: 'Password',
                    obscureText: _isPasswordObscured,
                    validator: AppValidators.password,
                    enabled: !_isLoading,
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordObscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _isPasswordObscured = !_isPasswordObscured),
                    ),
                  ),
                  const SizedBox(height: AppConstants.padL),

                  CustomTextFormField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm Password',
                    obscureText: _isConfirmPasswordObscured,
                    enabled: !_isLoading,
                    validator: (value) => AppValidators.valuesMatch(
                        value, _passwordController.text,
                        message: 'Passwords do not match'),
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordObscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() =>
                      _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
                    ),
                  ),
                  const SizedBox(height: AppConstants.padXL),

                  PrimaryGradientButton(
                    text: 'CREATE ACCOUNT',
                    onPressed: _isLoading ? null : _signUp,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppConstants.padM),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?",
                          style: theme.textTheme.bodyMedium),
                      TextButton(
                        onPressed: _isLoading ? null : () => context.go(AppRoutes.login),
                        child: Text('Sign In',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary)),
                      ),
                    ],
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



