import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/features/2_client_appointments/domain/models/appointment_with_details.dart';
import '../../../../app/helpers/contact_helper.dart';

class UpcomingAppointmentWidget extends StatelessWidget {
  final AppointmentWithDetails appointmentWithDetails;
  final VoidCallback? onTap;

  const UpcomingAppointmentWidget({
    super.key,
    required this.appointmentWithDetails,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appointment = appointmentWithDetails.appointment;
    final salon = appointmentWithDetails.salon;

    final dateStr = DateFormat('MMM d').format(appointment.startTime);
    final timeStr = DateFormat('h:mm a').format(appointment.startTime);
    final dayStr = DateFormat('EEE').format(appointment.startTime);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.08),
              theme.colorScheme.secondary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padL),
          child: Row(
            children: [
              // Date Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateStr.split(' ')[1],
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      dateStr.split(' ')[0].toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppConstants.padM),

              // Info Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$dayStr • $timeStr',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      salon.salonName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.scissors,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appointmentWithDetails.serviceNames,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // WhatsApp Button
              if (salon.whatsappNumber != null || salon.phoneNumber != null)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF25D366).withValues(alpha: 0.15),
                        const Color(0xFF25D366).withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF25D366).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {
                      final contactNum = salon.whatsappNumber ?? salon.phoneNumber!;
                      final msg = ContactHelper.createBookingMessage(
                        salonName: salon.salonName,
                        date: dateStr,
                        time: timeStr,
                      );
                      ContactHelper.openWhatsApp(
                        phone: contactNum,
                        message: msg,
                      );
                    },
                    icon: const Icon(
                      CupertinoIcons.chat_bubble_2_fill,
                      color: Color(0xFF25D366),
                      size: 22,
                    ),
                    tooltip: 'Contact Salon',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}