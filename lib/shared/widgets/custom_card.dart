import 'package:flutter/material.dart';
import '../../app/config/theme/app_constants.dart';
import '../../app/config/theme/app_colors.dart';

/// Enhanced custom card with hover effects and modern styling
class CustomCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Gradient? gradient;
  final Color? color;
  final double? elevation;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.gradient,
    this.color,
    this.elevation,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: AppConstants.durationFast,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final baseColor = widget.color ?? theme.cardTheme.color ?? theme.cardColor;
    final baseShadow = isDarkMode ? AppColors.darkShadowSm : AppColors.lightShadowSm;

    return MouseRegion(
      onEnter: widget.onTap != null ? (_) {
        setState(() => _isHovering = true);
        _hoverController.forward();
      } : null,
      onExit: widget.onTap != null ? (_) {
        setState(() => _isHovering = false);
        _hoverController.reverse();
      } : null,
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          final elevation = widget.elevation ?? (1.0 + (_hoverController.value * 4));

          return AnimatedContainer(
            duration: AppConstants.durationFast,
            transform: Matrix4.identity()
              ..translate(0.0, -2.0 * _hoverController.value),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              color: widget.gradient == null ? baseColor : null,
              borderRadius: AppConstants.radiusL,
              boxShadow: [
                BoxShadow(
                  color: (theme.cardTheme.shadowColor ?? Colors.black.withOpacity(0.1))
                      .withOpacity(0.08 + (_hoverController.value * 0.04)),
                  offset: Offset(0, 2 + (_hoverController.value * 4)),
                  blurRadius: 8 + (_hoverController.value * 8),
                  spreadRadius: -2,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            splashColor: widget.onTap != null
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            highlightColor: widget.onTap != null
                ? theme.colorScheme.primary.withOpacity(0.05)
                : Colors.transparent,
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(AppConstants.padM),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}