import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

import '../../../../shared/models/promotion_model.dart';
import '../../../../shared/widgets/loading_indicator.dart';

class PromotionCarousel extends StatefulWidget {
  final List<PromotionModel> promotions;
  final Function(PromotionModel)? onPromotionTap;
  final double height;

  const PromotionCarousel({
    super.key,
    required this.promotions,
    this.onPromotionTap,
    this.height = 210,
  });

  @override
  State<PromotionCarousel> createState() => _PromotionCarouselState();
}

class _PromotionCarouselState extends State<PromotionCarousel> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (widget.promotions.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: widget.promotions.length,
          itemBuilder: (context, index, realIndex) =>
              _buildPromotionCard(context, widget.promotions[index]),
          options: CarouselOptions(
            height: widget.height,
            viewportFraction: 0.9,
            initialPage: 0,
            enableInfiniteScroll: widget.promotions.length > 1,
            autoPlay: widget.promotions.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 1000),
            autoPlayCurve: Curves.easeInOutCubicEmphasized,
            enlargeCenterPage: true,
            enlargeFactor: 0.12,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
        ),
        if (widget.promotions.length > 1) ...[
          const SizedBox(height: 14),
          _buildDotIndicators(context),
        ],
      ],
    );
  }

  Widget _buildPromotionCard(BuildContext context, PromotionModel promotion) {
    return GestureDetector(
      onTap: () => widget.onPromotionTap?.call(promotion),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 22,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              CachedNetworkImage(
                imageUrl: promotion.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => ShimmerPlaceholder.rectangular(
                  height: widget.height,
                ),
                errorWidget: (context, url, error) =>
                    _buildImagePlaceholder(context, promotion),
              ),

              // One soft scrim: clear at the top, dark where the text sits.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.10),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),

              // Offer badge
              Positioned(
                top: 14,
                left: 14,
                child: ClientPill(
                  label: 'client.dashboard.special_offers'.tr().toUpperCase(),
                  color: Colors.white,
                  icon: CupertinoIcons.sparkles,
                  onDark: true,
                ),
              ),

              // Copy
              Positioned(
                left: 18,
                right: 18,
                bottom: 16,
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.1,
                  child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            promotion.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: -0.2,
                              color: Colors.white,
                            ),
                          ),
                          if (promotion.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              promotion.description,
                              maxLines: promotion.promoCode != null ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 13,
                                height: 1.35,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                          if (promotion.promoCode != null) ...[
                            const SizedBox(height: 10),
                            _PromoCode(code: promotion.promoCode!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_right,
                        size: 18,
                        color: AppColors.primaryDark,
                      ),
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

  Widget _buildDotIndicators(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.promotions.length,
        (index) {
          final active = _currentIndex == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 7,
            width: active ? 26 : 7,
            decoration: BoxDecoration(
              gradient: active ? AppColors.primaryGradient : null,
              color: active ? null : cs.primary.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context, PromotionModel promotion) {
    return Container(
      decoration: BoxDecoration(gradient: ClientTheme.heroGradient(context)),
      child: Center(
        child: Icon(
          CupertinoIcons.tag_fill,
          size: 64,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
      decoration: BoxDecoration(
        color: ClientTheme.inset(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ClientTheme.border(context)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ClientIconTile(
              icon: CupertinoIcons.tag,
              color: AppColors.primary,
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              'client.dashboard.no_promotions'.tr(),
              style: ClientTheme.caption(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashed-look ticket showing the promo code.
class _PromoCode extends StatelessWidget {
  final String code;
  const _PromoCode({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.ticket_fill, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            code,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
