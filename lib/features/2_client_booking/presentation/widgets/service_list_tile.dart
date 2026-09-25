import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/config/theme/app_colors.dart';
import '../../../../shared/models/service_model.dart';
import '../../../../shared/widgets/client_ui.dart';
import 'service_price.dart';

/// Selectable service row of the booking flow: check mark, name, description,
/// duration and price.
class ServiceSelectionCard extends StatelessWidget {
  final ServiceModel service;
  final bool isSelected;
  final VoidCallback onTap;

  const ServiceSelectionCard({
    super.key,
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ClientTheme.isDark(context);
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: service.name,
      child: ClientCard(
        onTap: onTap,
        radius: 22,
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        color: isSelected
            ? ClientTheme.tinted(context, AppColors.primary,
                light: 0.06, dark: 0.18)
            : null,
        borderColor: isSelected ? AppColors.primary : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _SelectMark(isSelected: isSelected),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTheme.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: ClientTheme.textPrimary(context),
                    ),
                  ),
                  if (service.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      service.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTheme.caption(context),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.time,
                        size: 13,
                        color: isSelected
                            ? (isDark ? cs.primary : AppColors.primaryDark)
                            : ClientTheme.textSecondary(context),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${service.durationMinutes} ${'common.min'.tr()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTheme.caption(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ServicePrice(service: service),
          ],
        ),
      ),
    );
  }
}

class _SelectMark extends StatelessWidget {
  final bool isSelected;

  const _SelectMark({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected ? AppColors.primaryGradient : null,
        border: isSelected
            ? null
            : Border.all(
                color: ClientTheme.textSecondary(context).withValues(alpha: 0.5),
                width: 2,
              ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: -3,
                ),
              ]
            : null,
      ),
      child: AnimatedScale(
        scale: isSelected ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: const Icon(
          CupertinoIcons.checkmark_alt,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
