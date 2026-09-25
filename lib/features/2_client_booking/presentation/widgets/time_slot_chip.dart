import 'package:flutter/material.dart';

import '../../../../app/config/theme/app_colors.dart';
import '../../../../app/config/theme/app_text_styles.dart';
import '../../../../shared/widgets/client_ui.dart';

/// A chip for one available time slot. Fills the width it is given.
class TimeSlotChip extends StatelessWidget {
  final String slot;
  final bool isSelected;
  final VoidCallback onTap;

  const TimeSlotChip({
    super.key,
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    return Semantics(
      button: true,
      selected: isSelected,
      label: slot,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 48,
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : ClientTheme.card(context),
          borderRadius: radius,
          border: Border.all(
            color: isSelected ? Colors.transparent : ClientTheme.border(context),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    slot,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color:
                          isSelected ? Colors.white : ClientTheme.textPrimary(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
