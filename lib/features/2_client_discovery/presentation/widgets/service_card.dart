import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
import 'package:pendeza/shared/widgets/service_category_icon.dart';

const Color _kDiscount = Color(0xFFEF4444);
const Color _kPopular = Color(0xFFF5A623);

Color _priceColor(BuildContext context, {required bool discounted}) {
  if (discounted) return _kDiscount;
  return ClientTheme.isDark(context)
      ? Theme.of(context).colorScheme.primary
      : AppColors.primaryDark;
}

/// Vertical service card for category lists.
///
/// Shows the image (or a tinted category icon), name with a "Popular" badge,
/// duration, price with a discount strike-through, and a selected state.
class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final bool isSelected;
  final VoidCallback? onTap;

  const ServiceCard({
    super.key,
    required this.service,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      onTap: onTap,
      radius: 22,
      padding: const EdgeInsets.all(12),
      color: isSelected ? ClientTheme.tinted(context, AppColors.primary) : null,
      borderColor: isSelected ? AppColors.primary : null,
      child: Row(
        children: [
          _ServiceThumb(service: service),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.time,
                          size: 13,
                          color: ClientTheme.textSecondary(context),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${service.durationMinutes} ${'common.min'.tr()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTheme.caption(context),
                          ),
                        ),
                      ],
                    ),
                    if (service.isPopular)
                      ClientPill(
                        label: 'client.salon_details.popular'.tr(),
                        color: _kPopular,
                        icon: CupertinoIcons.flame_fill,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _priceColor(context, discounted: service.hasDiscount),
                ),
              ),
              const SizedBox(height: 6),
              if (isSelected)
                const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: AppColors.primary,
                  size: 24,
                )
              else if (onTap != null)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.chevron_right,
                    size: 12,
                    color: ClientTheme.isDark(context)
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.primaryDark,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceThumb extends StatelessWidget {
  final ServiceModel service;

  const _ServiceThumb({required this.service});

  @override
  Widget build(BuildContext context) {
    final tone = ClientPalette.forKey(service.category);
    final dark = ClientTheme.isDark(context);
    final fallback = Center(
      child: Icon(
        serviceCategoryIcon(service.category),
        size: 26,
        color: dark ? Color.lerp(tone, Colors.white, 0.25) : tone,
      ),
    );

    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: tone.withValues(alpha: dark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: service.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: service.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => fallback,
                      errorWidget: (context, url, error) => fallback,
                    )
                  : fallback,
            ),
          ),
          if (service.hasDiscount)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _kDiscount,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ClientTheme.card(context), width: 2),
                ),
                child: Text(
                  '-${service.discountPercentage.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontal featured service card for the carousel.
///
/// Fixed 176 x 214: image area with a "Featured"/"Popular" badge, then name,
/// duration and price.
class FeaturedServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;

  static const double width = 176;
  static const double height = 214;

  const FeaturedServiceCard({
    super.key,
    required this.service,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tone = ClientPalette.forKey(service.category);
    final dark = ClientTheme.isDark(context);

    return SizedBox(
      width: width,
      height: height,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.15,
        child: ClientCard(
          onTap: onTap,
          radius: 24,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 104,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            tone.withValues(alpha: dark ? 0.35 : 0.22),
                            tone.withValues(alpha: dark ? 0.15 : 0.08),
                          ],
                        ),
                      ),
                      child: service.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: service.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  _placeholder(tone, dark),
                              errorWidget: (context, url, error) =>
                                  _placeholder(tone, dark),
                            )
                          : _placeholder(tone, dark),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _overlayBadge(),
                    ),
                    if (service.hasDiscount)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _kDiscount,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${service.discountPercentage.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                          height: 1.25,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.time,
                            size: 12,
                            color: ClientTheme.textSecondary(context),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${service.durationMinutes} ${'common.min'.tr()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ClientTheme.caption(context)
                                  .copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              AppFormatters.formatCurrency(
                                  service.effectivePrice),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _priceColor(
                                  context,
                                  discounted: service.hasDiscount,
                                ),
                              ),
                            ),
                          ),
                          if (service.hasDiscount) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                AppFormatters.formatCurrency(service.price),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ClientTheme.caption(context).copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(Color tone, bool dark) {
    return Center(
      child: Icon(
        serviceCategoryIcon(service.category),
        size: 36,
        color: dark ? Color.lerp(tone, Colors.white, 0.3) : tone,
      ),
    );
  }

  Widget _overlayBadge() {
    final featured = service.isFeatured;
    final color = featured ? AppColors.primary : _kPopular;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            featured ? CupertinoIcons.star_fill : CupertinoIcons.flame_fill,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            featured
                ? 'client.salon_details.featured'.tr()
                : 'client.salon_details.popular'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
