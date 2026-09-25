import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/config/app_config.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/features/2_client_appointments/domain/models/appointment_with_details.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

/// Visual status of an appointment (label, colour, icon).
class AppointmentStatusStyle {
  final String label;
  final Color color;
  final IconData icon;

  /// True for finished / cancelled bookings, drawn in a quieter style.
  final bool muted;

  const AppointmentStatusStyle({
    required this.label,
    required this.color,
    required this.icon,
    this.muted = false,
  });

  static AppointmentStatusStyle of(AppointmentModel appointment) {
    switch (appointment.status.toLowerCase()) {
      case 'pending payment':
        return const AppointmentStatusStyle(
          label: 'Pending',
          color: Color(0xFFF5A623),
          icon: CupertinoIcons.clock_fill,
        );
      case 'confirmed':
        if (appointment.startTime.isAfter(DateTime.now())) {
          return const AppointmentStatusStyle(
            label: 'Upcoming',
            color: AppColors.primary,
            icon: CupertinoIcons.checkmark_circle_fill,
          );
        }
        return const AppointmentStatusStyle(
          label: 'Completed',
          color: Color(0xFF00B894),
          icon: CupertinoIcons.checkmark_seal_fill,
          muted: true,
        );
      case 'completed':
        return const AppointmentStatusStyle(
          label: 'Completed',
          color: Color(0xFF00B894),
          icon: CupertinoIcons.checkmark_seal_fill,
          muted: true,
        );
      case 'cancelled':
        return const AppointmentStatusStyle(
          label: 'Cancelled',
          color: Color(0xFFFF6B6B),
          icon: CupertinoIcons.xmark_circle_fill,
          muted: true,
        );
      case 'no show':
      case 'noshow':
        return const AppointmentStatusStyle(
          label: 'No show',
          color: Color(0xFF8A8FA0),
          icon: CupertinoIcons.person_badge_minus,
          muted: true,
        );
      case 'payment failed':
        return const AppointmentStatusStyle(
          label: 'Payment failed',
          color: Color(0xFFFF6B6B),
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          muted: true,
        );
      default:
        return AppointmentStatusStyle(
          label: appointment.status,
          color: const Color(0xFF8A8FA0),
          icon: CupertinoIcons.info_circle_fill,
          muted: true,
        );
    }
  }
}

/// One appointment in the "My Appointments" lists.
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
    final appointment = details.appointment;
    final style = AppointmentStatusStyle.of(appointment);
    final start = appointment.startTime;

    return ClientCard(
      onTap: onTap,
      radius: 26,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppointmentDateBlock(date: start, muted: style.muted),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClientPill(
                      label: style.label,
                      color: style.color,
                      icon: style.icon,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.salon.salonName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTheme.heading(context).copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            CupertinoIcons.scissors,
                            size: 13,
                            color: ClientTheme.textSecondary(context),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            details.serviceNames,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTheme.caption(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Time · duration · price
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: ClientTheme.inset(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _Meta(
                  icon: CupertinoIcons.clock,
                  text: AppFormatters.formatTime(start),
                ),
                const SizedBox(width: 14),
                _Meta(
                  icon: CupertinoIcons.hourglass,
                  text: '${appointment.durationMinutes} min',
                ),
                const Spacer(),
                Text(
                  AppFormatters.formatCurrency(appointment.totalPrice),
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: ClientTheme.isDark(context)
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),

          // TEMPORARILY DISABLED - Payments turned off for App Store submission
          if (AppConfig.paymentsEnabled &&
              appointment.status == AppointmentStatus.pendingPayment &&
              onCompletePayment != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCompletePayment,
                icon: const Icon(CupertinoIcons.creditcard, size: 18),
                label: const Text('Complete Payment'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  foregroundColor: const Color(0xFF2B1B00),
                  minimumSize: const Size(0, 48),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            if (appointment.canCompletePayment) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.clock,
                    size: 13,
                    color: Color(0xFFB57500),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Payment expires soon. Complete now to confirm your booking.',
                      style: ClientTheme.caption(context).copyWith(
                        fontSize: 11.5,
                        color: const Color(0xFFB57500),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Calendar-style day tile ("23 / SEP"), gradient when active, quiet when past.
class AppointmentDateBlock extends StatelessWidget {
  final DateTime date;
  final bool muted;
  final double width;

  const AppointmentDateBlock({
    super.key,
    required this.date,
    this.muted = false,
    this.width = 62,
  });

  @override
  Widget build(BuildContext context) {
    final dark = ClientTheme.isDark(context);
    final fg = muted
        ? (dark ? Colors.white70 : const Color(0xFF636E72))
        : Colors.white;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: muted ? null : AppColors.primaryGradient,
        color: muted ? ClientTheme.inset(context) : null,
        borderRadius: BorderRadius.circular(18),
        border: muted ? Border.all(color: ClientTheme.border(context)) : null,
        boxShadow: muted
            ? null
            : [
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
            DateFormat('MMM').format(date).toUpperCase(),
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: fg.withValues(alpha: 0.9),
            ),
          ),
          Text(
            '${date.day}',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: fg,
            ),
          ),
          Text(
            DateFormat('EEE').format(date),
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: fg.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: ClientTheme.textSecondary(context)),
        const SizedBox(width: 6),
        Text(
          text,
          style: ClientTheme.body(context).copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
