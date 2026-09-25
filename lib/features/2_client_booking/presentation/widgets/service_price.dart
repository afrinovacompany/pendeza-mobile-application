import 'package:flutter/material.dart';

import '../../../../app/config/theme/app_colors.dart';
import '../../../../app/config/theme/app_text_styles.dart';
import '../../../../app/utils/formatters.dart';
import '../../../../shared/models/service_model.dart';
import '../../../../shared/widgets/client_ui.dart';

/// The price a customer pays for [service] ([ServiceModel.effectivePrice]),
/// with the crossed-out list price above it when the service is discounted.
///
/// This is the same number the booking total is built from.
class ServicePrice extends StatelessWidget {
  final ServiceModel service;
  final double fontSize;

  const ServicePrice({super.key, required this.service, this.fontSize = 15});

  @override
  Widget build(BuildContext context) {
    final isDark = ClientTheme.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (service.hasDiscount)
          Text(
            AppFormatters.formatCurrency(service.price),
            style: ClientTheme.caption(context).copyWith(
              decoration: TextDecoration.lineThrough,
              fontSize: 11,
            ),
          ),
        Text(
          AppFormatters.formatCurrency(service.effectivePrice),
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: isDark
                ? Theme.of(context).colorScheme.primary
                : AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}
