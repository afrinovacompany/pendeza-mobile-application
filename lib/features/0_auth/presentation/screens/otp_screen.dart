// otp_screen.dart
// IMPROVED VERSION - Countdown timer, expiration handling, better UX
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_router.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../auth_navigation.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_chrome.dart';

class OtpScreen extends StatefulWidget {
  final String sessionId;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.sessionId,
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

  /// Latest Briq session id. Updated when a new code is sent (including resend).
  late String _sessionId;

  // Animation controller for shake effect on error
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionId;
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
                  color: Theme.of(context).colorScheme.onError.withValues(alpha: 0.85),
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
      sessionId: _sessionId,
      smsCode: _otpController.text,
    ));
  }

  // ============================================================================
  // RESEND OTP
  // ============================================================================

  void _resendOtp() {
    if (_resendCooldown > 0) return;

    context.read<AuthBloc>().add(PhoneSignInRequested(widget.phoneNumber));
    _otpController.clear();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
          _showErrorSnackBar(state);
          // Clear OTP field on error
          _otpController.clear();
          _pinputFocusNode.requestFocus();
        } else if (state is PhoneVerificationCodeSent) {
          setState(() => _sessionId = state.sessionId);
          _startCountdown();
          _startResendCooldown();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('auth.otp.code_sent'.tr()),
              backgroundColor: theme.colorScheme.primary,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else if (state is Authenticated) {
          goAfterAuthenticated(context, state);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return AuthScaffold(
            isLoading: isLoading,
            loadingMessage: 'auth.otp.verifying'.tr(),
            body: AuthPageBody(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(
                      title: 'auth.otp.title'.tr(),
                      subtitle: 'auth.otp.description'.tr(args: [widget.phoneNumber]),
                      leading: Icon(
                        Icons.shield_outlined,
                        size: AuthChrome.iconSize,
                        color: _isExpired
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AuthChrome.fieldGap),

                    _buildCountdownTimer(theme),

                    const SizedBox(height: AuthChrome.headerGap),

                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: child,
                        );
                      },
                      child: _buildPinInput(theme, isLoading),
                    ),
                    const SizedBox(height: AuthChrome.headerGap),

                    PrimaryGradientButton(
                      text: _isExpired
                          ? 'auth.otp.expired'.tr()
                          : 'auth.otp.button'.tr(),
                      onPressed: (isLoading || _isExpired) ? null : _verifyOtp,
                      isLoading: isLoading,
                      height: AuthChrome.ctaHeight,
                    ),

                    const SizedBox(height: AuthChrome.actionGap),

                    _buildResendSection(theme, isLoading),

                    const SizedBox(height: AuthChrome.titleGap),

                    Text(
                      'auth.otp.helper'.tr(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: AuthChrome.subtitleOpacity,
                        ),
                      ),
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

  // ============================================================================
  // IMPROVED: Countdown timer widget
  // ============================================================================

  Widget _buildPinInput(ThemeData theme, bool isLoading) {
    const pinCount = 6;
    const pinGap = 8.0;
    const preferredWidth = 56.0;
    const preferredHeight = 60.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxPinWidth =
            (constraints.maxWidth - pinGap * (pinCount - 1)) / pinCount;
        final pinWidth = maxPinWidth.clamp(32.0, preferredWidth);
        final pinHeight = pinWidth * (preferredHeight / preferredWidth);

        final defaultPinTheme = PinTheme(
          width: pinWidth,
          height: pinHeight,
          textStyle: theme.textTheme.headlineMedium?.copyWith(
            fontSize: pinWidth < 44 ? 18 : null,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppConstants.radiusM,
            border: Border.all(color: theme.dividerColor),
          ),
        );

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Pinput(
            controller: _otpController,
            focusNode: _pinputFocusNode,
            length: pinCount,
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
            separatorBuilder: (_) => const SizedBox(width: pinGap),
            pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
            showCursor: true,
            enabled: !isLoading && !_isExpired,
            onCompleted: (pin) => _verifyOtp(),
            validator: (s) {
              if (_isExpired) return 'auth.otp.expired'.tr();
              return s?.length == 6 ? null : 'auth.otp.incomplete'.tr();
            },
            hapticFeedbackType: HapticFeedbackType.lightImpact,
            cursor: Container(
              width: 2,
              height: pinHeight * 0.4,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountdownTimer(ThemeData theme) {
    final color = _isExpired
        ? theme.colorScheme.error
        : (_remainingSeconds <= 30
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Icon(
              _isExpired ? Icons.timer_off : Icons.timer_outlined,
              size: 20,
              color: color,
            ),
            Text(
              _isExpired
                  ? 'auth.otp.expired'.tr()
                  : 'auth.otp.expires_in'.tr(args: [_formatTime(_remainingSeconds)]),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResendSection(ThemeData theme, bool isLoading) {
    final canResend = _resendCooldown == 0 && !isLoading;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'auth.otp.didnt_receive'.tr(),
          style: theme.textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: canResend ? _resendOtp : null,
          child: Text(
            _resendCooldown > 0
                ? 'auth.otp.resend_in'.tr(args: ['$_resendCooldown'])
                : 'auth.otp.resend_action'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: canResend
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}