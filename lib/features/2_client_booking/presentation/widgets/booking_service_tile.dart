import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/models/service_model.dart';
import '../../../../shared/widgets/client_ui.dart';
import '../../../../shared/widgets/service_category_icon.dart';
import 'service_price.dart';

/// One service line of the booking summary: icon, name, duration and price.
class BookingServiceTile extends StatelessWidget {
  final ServiceModel service;

  const BookingServiceTile({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClientIconTile(
            icon: serviceCategoryIcon(service.category),
            color: ClientPalette.forKey(service.category),
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTheme.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: ClientTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${service.durationMinutes} ${'common.min'.tr()}',
                  style: ClientTheme.caption(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ServicePrice(service: service, fontSize: 14.5),
        ],
      ),
    );
  }
}
