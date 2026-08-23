import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/custom_card.dart';

/// A reusable card widget for selecting a user role during onboarding.
class RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDisabled = onTap == null; // Check if the card is disabled

    return Opacity(
      // Dim the card slightly if it's disabled (e.g., during loading)
      opacity: isDisabled ? 0.6 : 1.0,
      child: CustomCard(
        onTap: isDisabled ? null : onTap, // Disable tap if callback is null
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.padL, // Increased vertical padding
            horizontal: AppConstants.padM,
          ),
          child: Row(
            children: [
              // Icon with background
              Container(
                padding: const EdgeInsets.all(AppConstants.padM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32, // Slightly larger icon
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppConstants.padL),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.padXXS),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        // Consistent secondary text color
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron indicator
              const SizedBox(width: AppConstants.padS),
              Icon(
                CupertinoIcons.chevron_forward,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
