import 'package:flutter/material.dart';

import '../../../../app/config/theme/app_constants.dart';

/// A simple row to display total duration or similar summary lines.
class BookingTotalRow extends StatelessWidget {
  final String title;
  final String value;

  const BookingTotalRow({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.padXS / 2), // Reduced padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7), // Secondary color for title
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold, // Bold value
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}