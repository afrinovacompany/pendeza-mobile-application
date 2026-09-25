import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/config/theme/app_text_styles.dart';
import '../../../../shared/widgets/client_ui.dart';

/// Gradient "ticket" with the salon and the chosen date and time.
class AppointmentSummaryCard extends StatelessWidget {
  final String salonName;
  final DateTime? appointmentDateTime;

  const AppointmentSummaryCard({
    super.key,
    required this.salonName,
    required this.appointmentDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final when = appointmentDateTime;

    return ClientBrandHero(
      margin: EdgeInsets.zero,
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                ),
                child: const Icon(
                  CupertinoIcons.scissors,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'client.booking.your_booking'.tr().toUpperCase(),
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      salonName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (when != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: _When(
                      icon: CupertinoIcons.calendar,
                      label: 'common.date'.tr(),
                      value: DateFormat('EEE, MMM d').format(when),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                  Expanded(
                    flex: 4,
                    child: _When(
                      icon: CupertinoIcons.clock,
                      label: 'common.time'.tr(),
                      value: DateFormat.jm().format(when),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _When extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _When({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
