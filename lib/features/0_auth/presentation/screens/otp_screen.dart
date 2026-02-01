// otp_screen.dart
// IMPROVED VERSION - Countdown timer, expiration handling, better UX
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_router.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

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

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _pinputFocusNode = FocusNode();

  // IMPROVED: Countdown timer for code expiration
  Timer? _countdownTimer;
  int _remainingSeconds = 120; // 2 minutes
  bool _isExpired = false;

  // Track resend cooldown
  int _resendCooldown = 0;
  Timer? _resendTimer;

  // Animation controller for shake effect on error
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _setupShakeAnimation();

    // Auto-focus the PIN input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinputFocusNode.requestFocus();
    });
  }

  void _setupShakeAnimation() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _remainingSeconds = 120;
    _isExpired = false;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        setState(() => _isExpired = true);
        timer.cancel();
      }
    });
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendCooldown = 30; // 30 seconds cooldown

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _pinputFocusNode.dispose();
    _countdownTimer?.cancel();
    _resendTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  // ============================================================================
  // IMPROVED: Error handling with visual feedback
  // ============================================================================

  void _showErrorSnackBar(AuthError error) {
    if (!mounted) return;

    // Shake the PIN input for visual feedback
    _shakeController.forward();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error.message,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (error.recoveryHint != null) ...[
              const SizedBox(height: 4),
              Text(
                error.recoveryHint!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================================
  // VERIFY OTP
  // ============================================================================

  Future<void> _verifyOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Check if code has expired
    if (_isExpired) {
      _showErrorSnackBar(AuthError.verificationExpired());
      return;
    }

    // Dispatch event to BLoC
    context.read<AuthBloc>().add(OtpVerificationRequested(
      verificationId: widget.verificationId,
      smsCode: _otpController.text,
    ));
  }

  // ============================================================================
  // RESEND OTP
  // ============================================================================

  void _resendOtp() {
    if (_resendCooldown > 0) return;

    context.read<AuthBloc>().add(PhoneSignInRequested(widget.phoneNumber));

    _startResendCooldown();
    _startCountdown();
    _otpController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('New verification code sent!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          if (state.user.role == 'owner') {
            context.go(AppRoutes.ownerHome);
          } else {
            context.go(AppRoutes.clientHome);
          }
        } else if (state is RoleSelectionRequired) {
          context.go(AppRoutes.roleSelection);
        } else if (state is ClientProfileSetupRequired) {
          context.go(AppRoutes.clientSetup);
        } else if (state is AuthError) {
          _showErrorSnackBar(state);
          // Clear OTP field on error
          _otpController.clear();
          _pinputFocusNode.requestFocus();
        } else if (state is PhoneVerificationCodeSent) {
          // New code sent (resend) - restart timer
          _startCountdown();
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: BackButton(
                color: theme.colorScheme.onSurface,
                onPressed: isLoading ? null : () => context.pop(),
              ),
            ),
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
                            // Icon
                            Icon(
                              Icons.shield_outlined,
                              size: 80,
                              color: _isExpired
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                            const SizedBox(height: AppConstants.padL),

                            // Title
                            Text(
                              'auth.otp.title'.tr(),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.displayMedium,
                            ),
                            const SizedBox(height: AppConstants.padS),

                            // Description
                            Text(
                              'auth.otp.description'.tr(args: [widget.phoneNumber]),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: AppConstants.padL),

                            // IMPROVED: Countdown timer display
                            _buildCountdownTimer(theme),

                            const SizedBox(height: AppConstants.padXL),

                            // IMPROVED: Animated PIN input
                            AnimatedBuilder(
                              animation: _shakeAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_shakeAnimation.value, 0),
                                  child: child,
                                );
                              },
                              child: Pinput(
                                controller: _otpController,
                                focusNode: _pinputFocusNode,
                                length: 6,
                                defaultPinTheme: defaultPinTheme,
                                focusedPinTheme: defaultPinTheme.copyWith(
                                  decoration: defaultPinTheme.decoration!.copyWith(
                                    border: Border.all(
                                      color: _isExpired
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                submittedPinTheme: defaultPinTheme.copyWith(
                                  decoration: defaultPinTheme.decoration!.copyWith(
                                    color: theme.colorScheme.primaryContainer,
                                    border: Border.all(
                                      color: theme.colorScheme.primary,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                errorPinTheme: defaultPinTheme.copyWith(
                                  decoration: defaultPinTheme.decoration!.copyWith(
                                    border: Border.all(
                                      color: theme.colorScheme.error,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                                showCursor: true,
                                enabled: !isLoading && !_isExpired,
                                onCompleted: (pin) => _verifyOtp(),
                                validator: (s) {
                                  if (_isExpired) return 'Code expired';
                                  return s?.length == 6 ? null : 'auth.otp.incomplete'.tr();
                                },
                                hapticFeedbackType: HapticFeedbackType.lightImpact,
                                cursor: Container(
                                  width: 2,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppConstants.padXL),

                            // Verify Button
                            PrimaryGradientButton(
                              text: _isExpired ? 'Code Expired' : 'auth.otp.button'.tr(),
                              onPressed: (isLoading || _isExpired) ? null : _verifyOtp,
                              isLoading: isLoading,
                            ),

                            const SizedBox(height: AppConstants.padL),

                            // IMPROVED: Resend section with cooldown
                            _buildResendSection(theme, isLoading),

                            const SizedBox(height: AppConstants.padS),

                            // Helper text
                            Text(
                              'Enter the 6-digit code we sent to your phone',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Verifying code...',
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

  // ============================================================================
  // IMPROVED: Countdown timer widget
  // ============================================================================

  Widget _buildCountdownTimer(ThemeData theme) {
    final color = _isExpired
        ? theme.colorScheme.error
        : (_remainingSeconds <= 30
        ? Colors.orange
        : theme.colorScheme.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isExpired ? Icons.timer_off : Icons.timer_outlined,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            _isExpired
                ? 'Code expired'
                : 'Code expires in ${_formatTime(_remainingSeconds)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // IMPROVED: Resend section with cooldown
  // ============================================================================

  Widget _buildResendSection(ThemeData theme, bool isLoading) {
    final canResend = _resendCooldown == 0 && !isLoading;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Didn\'t receive the code?',
          style: theme.textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: canResend ? _resendOtp : null,
          child: Text(
            _resendCooldown > 0
                ? 'Resend in ${_resendCooldown}s'
                : 'Resend',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: canResend
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}