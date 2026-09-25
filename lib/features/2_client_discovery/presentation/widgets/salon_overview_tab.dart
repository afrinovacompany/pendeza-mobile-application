import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/app/utils/business_hours_utils.dart';
import 'package:pendeza/features/2_client_discovery/presentation/widgets/salon_description_widget.dart';
import 'package:pendeza/features/2_client_discovery/presentation/widgets/saloon_gallery_widget.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_bloc.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_state.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class SalonOverviewTab extends StatelessWidget {
  final SalonModel salon;

  const SalonOverviewTab({super.key, required this.salon});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Rating, location and quick actions
          BlocBuilder<ReviewsBloc, ReviewsState>(
            builder: (context, state) {
              final loaded = state is ReviewsLoaded ? state : null;
              return SalonInfoCard(
                salon: salon,
                averageRating: loaded?.averageRating ?? 0,
                totalReviews: loaded?.totalReviews ?? 0,
              );
            },
          ),
          const SizedBox(height: 20),

          // 2. About + what the salon offers
          SalonDescriptionSection(salon: salon),
          const SizedBox(height: 24),

          // 3. Gallery
          if (salon.allImages.isNotEmpty) SalonGalleryPreview(salon: salon),

          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INFO CARD - rating, location and Call / Chat / Map / Hours actions
// ═════════════════════════════════════════════════════════════════════════════

class SalonInfoCard extends StatelessWidget {
  final SalonModel salon;
  final double averageRating;
  final int totalReviews;

  const SalonInfoCard({
    super.key,
    required this.salon,
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    final hasRating = totalReviews > 0 && averageRating > 0;
    final place = salon.district ?? salon.region ?? 'Tanzania';

    final actions = <Widget>[
      if (salon.phoneNumber != null)
        _ActionTile(
          label: 'client.salon_details.call'.tr(),
          icon: CupertinoIcons.phone_fill,
          color: AppColors.primary,
          onTap: () => _makePhoneCall(salon.phoneNumber!),
        ),
      if (salon.whatsappNumber != null)
        _ActionTile(
          label: 'client.salon_details.chat'.tr(),
          icon: CupertinoIcons.chat_bubble_2_fill,
          color: const Color(0xFF25D366),
          onTap: () => _openWhatsApp(salon.whatsappNumber!),
        ),
      if (_hasMapQuery(salon))
        _ActionTile(
          label: 'client.salon_details.map'.tr(),
          icon: CupertinoIcons.map_fill,
          color: const Color(0xFF3B82F6),
          onTap: () => _openMap(salon),
        ),
      _ActionTile(
        label: 'client.salon_details.hours'.tr(),
        icon: CupertinoIcons.clock_fill,
        color: const Color(0xFFF5A623),
        onTap: () => showSalonHoursSheet(context, salon),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
      child: ClientCard(
        padding: const EdgeInsets.all(16),
        radius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Rating
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5A623).withValues(
                      alpha: ClientTheme.isDark(context) ? 0.2 : 0.14,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.star_fill,
                        size: 16,
                        color: Color(0xFFF5A623),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasRating
                            ? averageRating.toStringAsFixed(1)
                            : 'client.salon_details.new_salon'.tr(),
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ClientTheme.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasRating
                        ? 'client.salon_details.reviews_count'
                            .tr(args: ['$totalReviews'])
                        : 'client.salon_details.no_reviews_title'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTheme.caption(context),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ClientPill(
                    label: place,
                    color: AppColors.primary,
                    icon: CupertinoIcons.location_solid,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: ClientTheme.border(context)),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final tile in actions) Expanded(child: tile),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _hasMapQuery(SalonModel salon) {
    return salon.address.trim().isNotEmpty ||
        (salon.district?.trim().isNotEmpty ?? false) ||
        (salon.region?.trim().isNotEmpty ?? false);
  }

  Future<void> _openMap(SalonModel salon) async {
    final query = [
      salon.salonName,
      if (salon.address.trim().isNotEmpty) salon.address.trim(),
      if (salon.district?.trim().isNotEmpty ?? false) salon.district!.trim(),
      if (salon.region?.trim().isNotEmpty ?? false) salon.region!.trim(),
    ].join(', ');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClientIconTile(icon: icon, color: color, size: 52, solid: true),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: ClientTheme.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: ClientTheme.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BUSINESS HOURS SHEET
// ═════════════════════════════════════════════════════════════════════════════

Future<void> showSalonHoursSheet(BuildContext context, SalonModel salon) {
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
    builder: (_) => SalonHoursSheet(salon: salon),
  );
}

class SalonHoursSheet extends StatelessWidget {
  final SalonModel salon;

  const SalonHoursSheet({super.key, required this.salon});

  @override
  Widget build(BuildContext context) {
    final status = BusinessHoursUtils.getStatus(
      openingTime: salon.openingTime,
      closingTime: salon.closingTime,
    );
    final isOpen = status == SalonStatus.open || status == SalonStatus.closing;
    final statusColor = BusinessHoursUtils.getStatusColor(status);

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
          Row(
            children: [
              const ClientIconTile(
                icon: CupertinoIcons.clock_fill,
                color: Color(0xFFF5A623),
                size: 48,
                solid: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'client.salon_details.business_hours'.tr(),
                      style: ClientTheme.title(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      salon.salonName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTheme.caption(context),
                    ),
                  ],
                ),
              ),
              if (salon.hasBusinessHours)
                ClientPill(
                  label: isOpen
                      ? 'client.salon_details.open'.tr()
                      : 'client.salon_details.closed'.tr(),
                  color: statusColor,
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (salon.hasBusinessHours)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: ClientTheme.inset(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _TimeRow(
                    label: 'client.salon_details.opens_at'.tr(),
                    time: salon.openingTime!,
                  ),
                  Divider(height: 1, color: ClientTheme.border(context)),
                  _TimeRow(
                    label: 'client.salon_details.closes_at'.tr(),
                    time: salon.closingTime!,
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ClientTheme.inset(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'client.salon_details.hours_not_set'.tr(),
                textAlign: TextAlign.center,
                style: ClientTheme.body(context).copyWith(
                  color: ClientTheme.textSecondary(context),
                ),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 52),
              elevation: 0,
              textStyle: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text('client.salon_details.got_it'.tr()),
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String time;

  const _TimeRow({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ClientTheme.body(context))),
          Text(
            time,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: ClientTheme.isDark(context)
                  ? Theme.of(context).colorScheme.primary
                  : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
