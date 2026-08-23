import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../app/config/app_router.dart';
import '../../../../app/utils/validators.dart';
import '../../../../shared/widgets/text_form_field.dart';
import '../auth_navigation.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_chrome.dart';

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

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is RoleSelectionRequired) {
          context.go(AppRoutes.roleSelection);
        } else if (state is ClientProfileSetupRequired) {
          context.go(AppRoutes.clientSetup);
        } else if (state is OwnerProfileSetupRequired) {
          context.go(AppRoutes.ownerSetup);
        } else if (state is AuthError) {
          _showErrorSnackBar(state.message);
        } else if (state is Authenticated) {
          goAfterAuthenticated(context, state);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return AuthScaffold(
            isLoading: isLoading,
            loadingMessage: 'auth.signup.creating'.tr(),
            body: AuthPageBody(
              child: Form(
                key: _formKey,
                autovalidateMode: (_nameTouched || _emailTouched ||
                        _passwordTouched || _confirmPasswordTouched)
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(
                      title: 'auth.signup.title'.tr(),
                      subtitle: 'auth.signup.subtitle'.tr(),
                    ),
                    const SizedBox(height: AuthChrome.headerGap),

                    CustomTextFormField(
                      controller: _nameController,
                      labelText: 'auth.signup.name_label'.tr(),
                      hintText: 'auth.signup.name_hint'.tr(),
                      validator: AppValidators.notEmpty,
                      enabled: !isLoading,
                      onChanged: (value) {
                        if (_nameTouched) {
                          _formKey.currentState?.validate();
                        }
                      },
                    ),
                    const SizedBox(height: AuthChrome.fieldGap),

                    CustomTextFormField(
                      controller: _emailController,
                      labelText: 'auth.signup.email_label'.tr(),
                      hintText: 'common.email_hint'.tr(),
                      keyboardType: TextInputType.emailAddress,
                      validator: AppValidators.email,
                      enabled: !isLoading,
                      onChanged: (value) {
                        if (_emailTouched) {
                          _formKey.currentState?.validate();
                        }
                      },
                    ),
                    const SizedBox(height: AuthChrome.fieldGap),

                    CustomTextFormField(
                      controller: _passwordController,
                      labelText: 'auth.signup.password_label'.tr(),
                      obscureText: _isPasswordObscured,
                      validator: AppValidators.password,
                      enabled: !isLoading,
                      onChanged: (value) {
                        if (_passwordTouched) {
                          _formKey.currentState?.validate();
                        }
                        if (_confirmPasswordTouched &&
                            _confirmPasswordController.text.isNotEmpty) {
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
                    const SizedBox(height: AuthChrome.fieldGap),

                    CustomTextFormField(
                      controller: _confirmPasswordController,
                      labelText: 'auth.signup.confirm_password_label'.tr(),
                      obscureText: _isConfirmPasswordObscured,
                      enabled: !isLoading,
                      validator: (value) => AppValidators.valuesMatch(
                          value, _passwordController.text,
                          message: 'Passwords do not match'),
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
                    const SizedBox(height: AuthChrome.headerGap),

                    PrimaryGradientButton(
                      text: 'auth.signup.button'.tr(),
                      onPressed: isLoading ? null : _signUp,
                      isLoading: isLoading,
                      height: AuthChrome.ctaHeight,
                    ),
                    const SizedBox(height: AuthChrome.actionGap),

                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'auth.signup.have_account'.tr(),
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed:
                              isLoading ? null : () => context.go(AppRoutes.login),
                          child: Text(
                            'auth.signup.signin_link'.tr(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
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