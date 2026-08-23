import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/utils/formatters.dart';
import '../../../../shared/models/service_model.dart';
import '../../../../shared/widgets/custom_card.dart';

/// A card widget for displaying a selectable service item.
class ServiceSelectionCard extends StatelessWidget {
  final ServiceModel service;
  final bool isSelected;
  final VoidCallback onTap;

  const ServiceSelectionCard({
    super.key,
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Determine colors based on selection state using theme colors
    final borderColor = isSelected ? colorScheme.primary : Colors.transparent;
    final backgroundColor =
    isSelected ? colorScheme.primary.withValues(alpha: 0.05) : theme.cardColor;
    final iconColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.4);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      // Slightly dim title if not selected
      color: isSelected ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.8),
    );
    final detailsColor = colorScheme.onSurface.withValues(alpha: 0.7);

    return CustomCard(
      onTap: onTap,
      color: backgroundColor,
      padding: EdgeInsets.zero, // Remove default card padding
      child: Container(
        // Use container border for selection indicator
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: borderColor, width: 4.0)),
          borderRadius: AppConstants.radiusL, // Match card radius if needed visually
        ),
        padding: const EdgeInsets.symmetric(
            vertical: AppConstants.padM, horizontal: AppConstants.padL), // Adjusted padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
          children: [
            // Selection icon
            Icon(
              isSelected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: iconColor,
              size: 28,
            ),
            const SizedBox(width: AppConstants.padL),
            // Service details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: titleStyle,
                    maxLines: 2, // Allow title to wrap
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppConstants.padXXS),
                  // Show duration and price clearly
                  // FIXED: Changed from â€¢ to • (proper bullet)
                  Text(
                    '${service.durationMinutes} min • ${AppFormatters.formatCurrency(service.price)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: detailsColor,
                      fontWeight: FontWeight.w500, // Make details slightly bolder
                    ),
                  ),
                  // Show description if available
                  if (service.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppConstants.padXXS), // Add space
                      child: Text(
                        service.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: detailsColor.withValues(alpha: 0.8), // Slightly dimmer description
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}