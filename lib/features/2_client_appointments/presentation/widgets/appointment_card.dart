import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/features/2_client_appointments/domain/models/appointment_with_details.dart';
import 'package:pendeza/shared/widgets/custom_card.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentWithDetails details;

  const AppointmentCard({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUpcoming = details.appointment.startTime.isAfter(DateTime.now());

    return CustomCard(
      onTap: () {
        // TODO: Navigate to appointment detail view or show a dialog
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Salon Name
              Expanded(
                child: Text(
                  details.salon.salonName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.padS, vertical: AppConstants.padXXS),
                decoration: BoxDecoration(
                  color: (isUpcoming ? theme.colorScheme.primary : Colors.green)
                      .withOpacity(0.1),
                  borderRadius: AppConstants.radiusS,
                ),
                child: Text(
                  isUpcoming ? 'UPCOMING' : 'COMPLETED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isUpcoming ? theme.colorScheme.primary : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.padXXS),
          // Service Names
          Text(
            details.serviceNames,
            style:
            theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: AppConstants.padXL),
          // Date and Time
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 16, color: theme.colorScheme.onSurface.withOpacity(0.7)),
              const SizedBox(width: AppConstants.padXS),
              Text(
                AppFormatters.formatDate(details.appointment.startTime),
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              Icon(Icons.access_time_rounded,
                  size: 16, color: theme.colorScheme.onSurface.withOpacity(0.7)),
              const SizedBox(width: AppConstants.padXS),
              Text(
                AppFormatters.formatTime(details.appointment.startTime),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
