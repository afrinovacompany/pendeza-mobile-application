import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/appointment_model.dart';

/// Recent bookings list - shows last 10 appointments
class RecentBookingsSection extends StatelessWidget {
  final List<AppointmentModel> bookings;

  const RecentBookingsSection({
    super.key,
    required this.bookings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (bookings.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
          child: Text(
            'owner.clients.recent_bookings'.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.padM),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return _BookingItem(booking: bookings[index]);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(AppConstants.padL),
      padding: const EdgeInsets.all(AppConstants.padXL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.calendar,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppConstants.padM),
          Text(
            'owner.clients.no_bookings_title'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.padS),
          Text(
            'owner.clients.no_bookings_msg'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BookingItem extends StatelessWidget {
  final AppointmentModel booking;

  const _BookingItem({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.padM),
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CupertinoIcons.scissors,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getServicesSummary(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'TZS ${booking.totalPrice.toStringAsFixed(0)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateFormat('MMM d, h:mm a').format(booking.startTime),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusBadge(status: booking.status),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getServicesSummary() {
    if (booking.serviceIds.isEmpty) return 'Appointment';
    if (booking.serviceIds.length == 1) return '1 Service';
    return '${booking.serviceIds.length} Services';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLower = status.toLowerCase();

    Color bgColor;
    Color textColor;
    IconData icon;

    switch (statusLower) {
      case 'completed':
        bgColor = theme.colorScheme.tertiary.withValues(alpha: 0.15);
        textColor = theme.colorScheme.tertiary;
        icon = CupertinoIcons.check_mark_circled_solid;
        break;
      case 'confirmed':
        bgColor = theme.colorScheme.primary.withValues(alpha: 0.15);
        textColor = theme.colorScheme.primary;
        icon = CupertinoIcons.checkmark_seal_fill;
        break;
      case 'pending payment':
        bgColor = theme.colorScheme.secondary.withValues(alpha: 0.15);
        textColor = theme.colorScheme.secondary;
        icon = CupertinoIcons.time_solid;
        break;
      case 'cancelled':
        bgColor = theme.colorScheme.error.withValues(alpha: 0.15);
        textColor = theme.colorScheme.error;
        icon = CupertinoIcons.xmark_circle_fill;
        break;
      default:
        bgColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurface;
        icon = CupertinoIcons.circle_fill;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}