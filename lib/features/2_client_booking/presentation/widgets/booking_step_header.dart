import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

/// Header shared by the three booking steps: back button, title, salon name
/// and a progress bar (Services → Date & time → Confirm).
class BookingStepHeader extends StatelessWidget {
  /// Current step, 1-based.
  final int step;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  static const int totalSteps = 3;

  const BookingStepHeader({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    this.onBack,
  }) : assert(step >= 1 && step <= totalSteps);

  @override
  Widget build(BuildContext context) {
    final labels = [
      'client.booking.step_services'.tr(),
      'client.booking.step_time'.tr(),
      'client.booking.step_confirm'.tr(),
    ];

    return ClientBrandHero(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GlassCircleButton(
                icon: CupertinoIcons.back,
                size: 42,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'common.step'.tr(args: ['$step', '$totalSteps']),
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Row(
                children: [
                  for (var i = 0; i < totalSteps; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _StepSegment(
                        label: labels[i],
                        reached: i < step,
                        current: i == step - 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepSegment extends StatelessWidget {
  final String label;
  final bool reached;
  final bool current;

  const _StepSegment({
    required this.label,
    required this.reached,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: reached ? 1 : 0.28),
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            fontWeight: current ? FontWeight.w700 : FontWeight.w500,
            color: Colors.white.withValues(alpha: reached ? 1 : 0.65),
          ),
        ),
      ],
    );
  }
}
