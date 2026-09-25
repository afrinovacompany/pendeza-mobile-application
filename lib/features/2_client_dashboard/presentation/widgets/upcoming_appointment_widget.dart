import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/features/2_client_appointments/domain/models/appointment_with_details.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

import '../../../../app/helpers/contact_helper.dart';

/// "Up next" card for the nearest upcoming appointment.
class UpcomingAppointmentWidget extends StatelessWidget {
  final AppointmentWithDetails appointmentWithDetails;
  final VoidCallback? onTap;

  const UpcomingAppointmentWidget({
    super.key,
    required this.appointmentWithDetails,
    this.onTap,
  });

  /// Whole days from today to [when] (0 = today, 1 = tomorrow).
  int _daysAway(DateTime when) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(when.year, when.month, when.day).difference(today).inDays;
  }

  /// "Today", "Tomorrow" or "Wed, Sep 23".
  String _dayLabel(DateTime when) {
    final days = _daysAway(when);
    if (days == 0) return 'client.dashboard.today'.tr();
    if (days == 1) return 'client.dashboard.tomorrow'.tr();
    return DateFormat('EEE, MMM d').format(when);
  }

  @override
  Widget build(BuildContext context) {
    final appointment = appointmentWithDetails.appointment;
    final salon = appointmentWithDetails.salon;

    final dateStr = DateFormat('MMM d').format(appointment.startTime);
    final timeStr = DateFormat('h:mm a').format(appointment.startTime);
    final isToday = _daysAway(appointment.startTime) == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
      child: ClientCard(
        onTap: onTap,
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date block
            Container(
              width: 62,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dateStr.split(' ').last,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr.split(' ').first.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClientPill(
                    label: '${_dayLabel(appointment.startTime)} · $timeStr',
                    color: isToday ? const Color(0xFF00B894) : AppColors.primary,
                    icon: CupertinoIcons.clock_fill,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    salon.salonName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTheme.heading(context),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.scissors,
                        size: 13,
                        color: ClientTheme.textSecondary(context),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          appointmentWithDetails.serviceNames,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTheme.caption(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // WhatsApp
            if (salon.whatsappNumber != null || salon.phoneNumber != null) ...[
              const SizedBox(width: 10),
              Material(
                color: const Color(0xFF25D366).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
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
                  child: const Tooltip(
                    message: 'Contact Salon',
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(
                        CupertinoIcons.chat_bubble_2_fill,
                        color: Color(0xFF1FAF5A),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
