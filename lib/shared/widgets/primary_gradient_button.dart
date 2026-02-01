import 'package:flutter/material.dart';
import '../../app/config/theme/app_colors.dart';
import '../../app/config/theme/app_constants.dart';
import '../../app/config/theme/app_text_styles.dart';

/// Enhanced primary button with modern "Aura" effect
class PrimaryGradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? iconData;
  final bool isLoading;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const PrimaryGradientButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.iconData,
    this.isLoading = false,
    this.height,
    this.padding,
  });

  @override
  State<PrimaryGradientButton> createState() => _PrimaryGradientButtonState();
}

class _PrimaryGradientButtonState extends State<PrimaryGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          final glowIntensity = isEnabled ? _glowController.value : 0.0;

          return AnimatedContainer(
            duration: AppConstants.durationFast,
            height: widget.height ?? 50,
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : LinearGradient(
                colors: [
                  theme.disabledColor.withOpacity(0.3),
                  theme.disabledColor.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusValM),
              boxShadow: isEnabled
                  ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3 + (glowIntensity * 0.2)),
                  blurRadius: 12 + (glowIntensity * 8),
                  offset: const Offset(0, 4),
                  spreadRadius: glowIntensity * 2,
                ),
              ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isEnabled ? widget.onPressed : null,
                borderRadius: BorderRadius.circular(AppConstants.radiusValM),
                child: AnimatedScale(
                  scale: _isPressed ? 0.96 : 1.0,
                  duration: AppConstants.durationFast,
                  child: Container(
                    padding: widget.padding ??
                        const EdgeInsets.symmetric(
                          vertical: AppConstants.padS,
                          horizontal: AppConstants.padL,
                        ),
                    child: widget.isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.iconData != null) ...[
                          Icon(
                            widget.iconData,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: AppConstants.padXS),
                        ],
                        Flexible(
                          child: Text(
                            widget.text,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}