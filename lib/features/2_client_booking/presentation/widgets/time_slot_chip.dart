import 'package:flutter/material.dart';
import '../../../../app/config/theme/app_constants.dart';

/// A chip widget for displaying and selecting an available time slot.
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Use theme colors for selected/unselected states
    final containerColor = isSelected ? colorScheme.primary : theme.cardColor;
    final textColor = isSelected ? colorScheme.onPrimary : colorScheme.onSurface;
    final borderColor = isSelected ? colorScheme.primary : theme.dividerColor.withValues(alpha: 0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: AppConstants.radiusM, // Use theme constant
      child: AnimatedContainer( // Add animation for selection change
        duration: AppConstants.durationFast, // Use theme constant
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.padM, vertical: AppConstants.padS),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: AppConstants.radiusM, // Use theme constant
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
          boxShadow: isSelected ? [ // Add subtle shadow when selected
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : [],
        ),
        child: Text(
          slot,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
