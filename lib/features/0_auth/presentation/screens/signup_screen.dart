import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/widgets/adaptive/adaptive_app_bar.dart';
import '../../../../app/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../app/config/app_router.dart';
import '../../../../app/utils/validators.dart';
import '../../../../shared/widgets/text_form_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

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

  // 🔥 NEW: Track field interactions
  bool _nameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _confirmPasswordTouched = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    showAdaptiveSnackBar(
      context: context,
      message: message,
      isError: true,
    );
  }

  // 🔥 NEW: Use BLoC event instead of direct repository call
  Future<void> _signUp() async {
    setState(() {
      _nameTouched = true;
      _emailTouched = true;
      _passwordTouched = true;
      _confirmPasswordTouched = true;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Dispatch event to BLoC
    context.read<AuthBloc>().add(SignUpRequested(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
        isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is RoleSelectionRequired) {
          context.go(AppRoutes.roleSelection);
        } else if (state is Authenticated) {
          context.go(AppRoutes.clientHome);
        } else if (state is AuthError) {
          _showErrorSnackBar(state.message);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Scaffold(
            appBar: AdaptiveAppBar(
              title: '',
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: AdaptiveBackButton(
                color: theme.colorScheme.onSurface,
                onPressed: isLoading ? null : () => context.pop(),
              ),
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
                      child: Form(
                        key: _formKey,
                        // 🔥 NEW: Enable auto-validation after first interaction
                        autovalidateMode: (_nameTouched || _emailTouched ||
                            _passwordTouched || _confirmPasswordTouched)
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('auth.signup.title'.tr(),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displayMedium),
                            Text('Let\'s get you started!',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface.withAlpha(178))),
                            const SizedBox(height: AppConstants.padXL),

                            CustomTextFormField(
                              controller: _nameController,
                              labelText: 'auth.signup.name_label'.tr(),
                              hintText: 'auth.signup.name_hint'.tr(),
                              validator: AppValidators.notEmpty,
                              enabled: !isLoading,
                              // 🔥 NEW: Real-time validation
                              onChanged: (value) {
                                if (_nameTouched) {
                                  _formKey.currentState?.validate();
                                }
                              },
                            ),
                            const SizedBox(height: AppConstants.padL),

                            CustomTextFormField(
                              controller: _emailController,
                              labelText: 'auth.signup.email_label'.tr(),
                              hintText: 'common.email_hint'.tr(),
                              keyboardType: TextInputType.emailAddress,
                              validator: AppValidators.email,
                              enabled: !isLoading,
                              // 🔥 NEW: Real-time validation
                              onChanged: (value) {
                                if (_emailTouched) {
                                  _formKey.currentState?.validate();
                                }
                              },
                            ),
                            const SizedBox(height: AppConstants.padL),

                            CustomTextFormField(
                              controller: _passwordController,
                              labelText: 'auth.signup.password_label'.tr(),
                              obscureText: _isPasswordObscured,
                              validator: AppValidators.password,
                              enabled: !isLoading,
                              // 🔥 NEW: Real-time validation
                              onChanged: (value) {
                                if (_passwordTouched) {
                                  _formKey.currentState?.validate();
                                }
                                // Also re-validate confirm password if it was touched
                                if (_confirmPasswordTouched && _confirmPasswordController.text.isNotEmpty) {
                                  _formKey.currentState?.validate();
                                }
                              },
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
                              labelText: 'auth.signup.confirm_password_label'.tr(),
                              obscureText: _isConfirmPasswordObscured,
                              enabled: !isLoading,
                              validator: (value) => AppValidators.valuesMatch(
                                  value, _passwordController.text,
                                  message: 'Passwords do not match'),
                              // 🔥 NEW: Real-time validation
                              onChanged: (value) {
                                if (_confirmPasswordTouched) {
                                  _formKey.currentState?.validate();
                                }
                              },
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
                              text: 'auth.signup.button'.tr(),
                              onPressed: isLoading ? null : _signUp,
                              isLoading: isLoading,
                            ),
                            const SizedBox(height: AppConstants.padM),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("auth.signup.have_account".tr(),
                                    style: theme.textTheme.bodyMedium),
                                TextButton(
                                  onPressed: isLoading ? null : () => context.go(AppRoutes.login),
                                  child: Text('auth.signup.signin_link'.tr(),
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

                  // 🔥 IMPROVED: Better loading overlay
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
                                  'Creating your account...',
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