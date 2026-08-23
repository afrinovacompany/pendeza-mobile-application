import 'package:flutter/material.dart';

import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/utils/formatters.dart';
import '../../../../shared/models/service_model.dart';

/// A simple tile to display service name and price in the booking summary.
class BookingServiceTile extends StatelessWidget {
  final ServiceModel service;

  const BookingServiceTile({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.padXS / 2), // Reduced vertical padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Service Name (allow wrapping)
          Expanded(
            child: Text(
              service.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85), // Slightly softer text
              ),
            ),
          ),
          const SizedBox(width: AppConstants.padM),
          // Price
          Text(
            AppFormatters.formatCurrency(service.price),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500, // Make price slightly bolder
              color: theme.colorScheme.onSurface, // Standard text color
            ),
          ),
        ],
      ),
    );
  }
}