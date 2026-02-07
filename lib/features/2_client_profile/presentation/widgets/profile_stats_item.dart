import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';

/// A sleek vertical stat item used in the profile header.
class ProfileStatItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const ProfileStatItem({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusValM),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.padM,
          vertical: AppConstants.padXS,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}