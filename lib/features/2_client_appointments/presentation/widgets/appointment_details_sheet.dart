import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/app_config.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/app/helpers/contact_helper.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/features/2_client_appointments/domain/models/appointment_with_details.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';

import 'appointment_card.dart';

/// Bottom sheet with everything about one appointment.
///
/// [onCompletePayment] is only shown for pending bookings while payments are
/// enabled (they are switched off right now).
Future<void> showAppointmentDetailsSheet(
  BuildContext context,
  AppointmentWithDetails details, {
  VoidCallback? onCompletePayment,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: ClientTheme.card(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (sheetContext) => AppointmentDetailsSheet(
      details: details,
      onCompletePayment: onCompletePayment == null
          ? null
          : () {
              Navigator.of(sheetContext).pop();
              onCompletePayment();
            },
    ),
  );
}

class AppointmentDetailsSheet extends StatelessWidget {
  final AppointmentWithDetails details;
  final VoidCallback? onCompletePayment;

  const AppointmentDetailsSheet({
    super.key,
    required this.details,
    this.onCompletePayment,
  });

  @override
  Widget build(BuildContext context) {
    final appointment = details.appointment;
    final salon = details.salon;
    final style = AppointmentStatusStyle.of(appointment);
    final start = appointment.startTime;
    final contact = salon.whatsappNumber ?? salon.phoneNumber;
    final canContact = contact != null && !style.muted;
    final needsPayment = AppConfig.paymentsEnabled &&
        appointment.status == AppointmentStatus.pendingPayment &&
        onCompletePayment != null;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Salon + status
          Row(
            children: [
              ProfileAvatar(
                imageUrl: salon.primaryImage,
                fullName: salon.salonName,
                radius: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salon.salonName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTheme.title(context),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.location_solid,
                          size: 12,
                          color: ClientTheme.textSecondary(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            salon.district ?? salon.address,
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
              const SizedBox(width: 8),
              ClientPill(
                label: style.label,
                color: style.color,
                icon: style.icon,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // When
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: style.muted
                  ? null
                  : ClientTheme.heroGradient(context),
              color: style.muted ? ClientTheme.inset(context) : null,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _When(
                    icon: CupertinoIcons.calendar,
                    label: 'common.date'.tr(),
                    value: DateFormat('EEE, MMM d').format(start),
                    onDark: !style.muted,
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: (style.muted
                          ? ClientTheme.border(context)
                          : Colors.white.withValues(alpha: 0.35)),
                ),
                Expanded(
                  child: _When(
                    icon: CupertinoIcons.clock,
                    label: 'common.time'.tr(),
                    value: AppFormatters.formatTime(start),
                    onDark: !style.muted,
                    padLeft: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Services
          Text(
            'common.services'.tr().toUpperCase(),
            style: ClientTheme.label(context),
          ),
          const SizedBox(height: 8),
          if (details.services.isEmpty)
            Text(details.serviceNames, style: ClientTheme.body(context))
          else
            for (final service in details.services)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(service.name, style: ClientTheme.body(context)),
                    ),
                    Text(
                      AppFormatters.formatCurrency(service.effectivePrice),
                      style: ClientTheme.caption(context)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 10),
          Divider(height: 1, color: ClientTheme.border(context)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                CupertinoIcons.hourglass,
                size: 15,
                color: ClientTheme.textSecondary(context),
              ),
              const SizedBox(width: 6),
              Text(
                '${appointment.durationMinutes} min',
                style: ClientTheme.caption(context),
              ),
              const Spacer(),
              Text('common.total'.tr(), style: ClientTheme.caption(context)),
              const SizedBox(width: 10),
              Text(
                AppFormatters.formatCurrency(appointment.totalPrice),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: ClientTheme.isDark(context)
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Actions
          if (needsPayment) ...[
            FilledButton.icon(
              onPressed: onCompletePayment,
              icon: const Icon(CupertinoIcons.creditcard, size: 18),
              label: Text('client.booking.complete_payment_btn'.tr()),
              style: _buttonStyle(const Color(0xFFF5A623),
                  const Color(0xFF2B1B00)),
            ),
            const SizedBox(height: 10),
          ],
          if (canContact) ...[
            FilledButton.icon(
              onPressed: () {
                ContactHelper.openWhatsApp(
                  phone: contact,
                  message: ContactHelper.createBookingMessage(
                    salonName: salon.salonName,
                    date: DateFormat('MMM d').format(start),
                    time: AppFormatters.formatTime(start),
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 18),
              label: Text('client.appointments.contact_salon'.tr()),
              style: _buttonStyle(
                  const Color(0xFF25D366), const Color(0xFF06381C)),
            ),
            const SizedBox(height: 10),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 46),
              foregroundColor: ClientTheme.textSecondary(context),
              textStyle: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }

  ButtonStyle _buttonStyle(Color bg, Color fg) => FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: const Size(0, 52),
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
}

class _When extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool onDark;
  final bool padLeft;

  const _When({
    required this.icon,
    required this.label,
    required this.value,
    required this.onDark,
    this.padLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : ClientTheme.textPrimary(context);
    final sub = onDark
        ? Colors.white.withValues(alpha: 0.8)
        : ClientTheme.textSecondary(context);
    return Padding(
      padding: EdgeInsets.only(left: padLeft ? 16 : 0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: ClientTheme.label(context).copyWith(color: sub),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTheme.body(context).copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
