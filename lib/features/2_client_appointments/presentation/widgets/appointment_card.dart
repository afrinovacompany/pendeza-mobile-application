import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/features/2_client_appointments/domain/models/appointment_with_details.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/widgets/custom_card.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentWithDetails details;
  final VoidCallback? onTap;
  final VoidCallback? onCompletePayment;

  const AppointmentCard({
    super.key,
    required this.details,
    this.onTap,
    this.onCompletePayment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = details.appointment.status;
    final statusInfo = _getStatusInfo(status, theme);
    final Color secondaryTextColor = colorScheme.onSurface.withValues(alpha: 0.7);

    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.padL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Salon Name + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Salon icon + name
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        CupertinoIcons.building_2_fill,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        details.salon.salonName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.padS),
              // Enhanced Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: statusInfo.gradient,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusInfo.textColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusInfo.textColor.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (statusInfo.icon != null) ...[
                      Icon(
                        statusInfo.icon,
                        size: 12,
                        color: statusInfo.textColor,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      statusInfo.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusInfo.textColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.padM),

          // Service Names with icon
          Row(
            children: [
              Icon(
                CupertinoIcons.scissors,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  details.serviceNames,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.padM),

          // Info Row with gradient container
          Container(
            padding: const EdgeInsets.all(AppConstants.padM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.05),
                  colorScheme.secondary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                // Date
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.calendar,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          AppFormatters.monthDay.format(details.appointment.startTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // Time
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.time,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          AppFormatters.formatTime(details.appointment.startTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // Price with gradient
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppFormatters.formatCurrency(details.appointment.totalPrice),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pending payment action button
          if (status == AppointmentStatus.pendingPayment && onCompletePayment != null) ...[
            const SizedBox(height: AppConstants.padM),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade600, Colors.orange.shade500],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCompletePayment,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.creditcard, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text(
                          'Complete Payment',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (details.appointment.canCompletePayment) ...[
              const SizedBox(height: AppConstants.padXS),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      size: 14,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Payment expires soon. Complete now to confirm your booking.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  _StatusDisplayInfo _getStatusInfo(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'pending payment':
        return _StatusDisplayInfo(
          label: 'PENDING',
          textColor: Colors.orange.shade800,
          gradient: LinearGradient(
            colors: [Colors.orange.shade100, Colors.orange.shade50],
          ),
          icon: CupertinoIcons.clock_fill,
        );

      case 'confirmed':
        final isUpcoming = details.appointment.startTime.isAfter(DateTime.now());
        if (isUpcoming) {
          return _StatusDisplayInfo(
            label: 'UPCOMING',
            textColor: theme.colorScheme.primary,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.15),
                theme.colorScheme.secondary.withValues(alpha: 0.15),
              ],
            ),
            icon: CupertinoIcons.checkmark_circle_fill,
          );
        } else {
          return _StatusDisplayInfo(
            label: 'COMPLETED',
            textColor: Colors.green.shade700,
            gradient: LinearGradient(
              colors: [Colors.green.shade100, Colors.green.shade50],
            ),
            icon: CupertinoIcons.checkmark_seal_fill,
          );
        }

      case 'completed':
        return _StatusDisplayInfo(
          label: 'COMPLETED',
          textColor: Colors.green.shade700,
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.green.shade50],
          ),
          icon: CupertinoIcons.checkmark_seal_fill,
        );

      case 'cancelled':
        return _StatusDisplayInfo(
          label: 'CANCELLED',
          textColor: Colors.red.shade700,
          gradient: LinearGradient(
            colors: [Colors.red.shade100, Colors.red.shade50],
          ),
          icon: CupertinoIcons.xmark_circle_fill,
        );

      case 'no show':
      case 'noshow':
        return _StatusDisplayInfo(
          label: 'NO SHOW',
          textColor: Colors.grey.shade700,
          gradient: LinearGradient(
            colors: [Colors.grey.shade200, Colors.grey.shade100],
          ),
          icon: CupertinoIcons.person_badge_minus,
        );

      case 'payment failed':
        return _StatusDisplayInfo(
          label: 'FAILED',
          textColor: Colors.red.shade800,
          gradient: LinearGradient(
            colors: [Colors.red.shade100, Colors.red.shade50],
          ),
          icon: CupertinoIcons.exclamationmark_triangle_fill,
        );

      default:
        return _StatusDisplayInfo(
          label: status.toUpperCase(),
          textColor: Colors.grey.shade700,
          gradient: LinearGradient(
            colors: [Colors.grey.shade200, Colors.grey.shade100],
          ),
        );
    }
  }
}

class _StatusDisplayInfo {
  final String label;
  final Color textColor;
  final LinearGradient gradient;
  final IconData? icon;

  const _StatusDisplayInfo({
    required this.label,
    required this.textColor,
    required this.gradient,
    this.icon,
  });
}