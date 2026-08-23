import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/custom_card.dart';

/// Displays the core appointment details (Salon, Date, Time) in a prominent card.
class AppointmentSummaryCard extends StatelessWidget {
  final String salonName;
  final DateTime appointmentDateTime;

  const AppointmentSummaryCard({
    super.key,
    required this.salonName,
    required this.appointmentDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomCard(
      padding: const EdgeInsets.all(AppConstants.padL),
      // Use primary color with low opacity for background
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Salon Name
          Text(
            salonName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              // Use primary color directly for better contrast
              color: theme.colorScheme.primary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppConstants.padM),
          // Date Row
          _buildDetailRow(
            context,
            icon: CupertinoIcons.calendar_today,
            value: DateFormat.yMMMMEEEEd().format(appointmentDateTime), // Full date format
          ),
          const SizedBox(height: AppConstants.padS),
          // Time Row
          _buildDetailRow(
            context,
            icon: CupertinoIcons.time,
            value: DateFormat.jm().format(appointmentDateTime), // Time format
          ),
        ],
      ),
    );
  }

  /// Helper to build consistent rows with icon and text.
  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String value}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 20, // Consistent icon size
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: AppConstants.padM),
        Expanded( // Allow text to wrap if needed
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500, // Make details slightly bolder
              color: theme.colorScheme.onSurface.withValues(alpha: 0.9), // Slightly darker text
            ),
          ),
        ),
      ],
    );
  }
}