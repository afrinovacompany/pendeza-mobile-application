import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/features/2_client_favorites/presentation/widgets/favorite_icon_button.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/utils/placeholder_images.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

import '../../app/config/theme/app_constants.dart';

/// Photo-first salon card: full-bleed image with the name, location and a
/// couple of real details layered over a soft gradient.
///
/// Works at any size (dashboard carousel, discovery grid, favorites grid).
class SalonCard extends StatefulWidget {
  final SalonModel salon;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const SalonCard({
    super.key,
    required this.salon,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  State<SalonCard> createState() => _SalonCardState();
}

class _SalonCardState extends State<SalonCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppConstants.durationFast,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _scaleController.reverse();
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      _scaleController.reverse();
    }
  }

  /// Salon photo, falling back to a placeholder when the primary image URL is
  /// empty, null, or fails to load from the network.
  Widget _buildSalonImage(ColorScheme colorScheme) {
    final primaryUrl = widget.salon.primaryImage ?? '';
    final fallbackUrl = PlaceholderImages.forSalon(widget.salon.id);

    Widget loading() => Container(
          color: colorScheme.surfaceContainerHighest,
          child: const Center(child: CupertinoActivityIndicator()),
        );
    Widget broken() => Container(
          color: colorScheme.surfaceContainerHighest,
          child: Icon(
            CupertinoIcons.photo,
            color: colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        );
    Widget photo(String url, {Widget Function(BuildContext, String, Object)? onError}) =>
        CachedNetworkImage(
          imageUrl: url,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => loading(),
          errorWidget: onError ?? (context, url, error) => broken(),
        );

    if (primaryUrl.isEmpty) return photo(fallbackUrl);
    return photo(
      primaryUrl,
      onError: (context, url, error) => photo(fallbackUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final salon = widget.salon;

    final category =
        salon.serviceCategories.isNotEmpty ? salon.serviceCategories.first : null;
    final hasHours = salon.openingTime != null && salon.closingTime != null;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.98).animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
        ),
        child: Container(
          width: widget.width ?? 160,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 200;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'salon_image_${salon.id}',
                      child: _buildSalonImage(colorScheme),
                    ),

                    // Scrim: clear on top, dark under the text.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.10),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.30),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          stops: const [0.0, 0.32, 0.6, 1.0],
                        ),
                      ),
                    ),

                    // Favourite
                    Positioned(
                      top: 10,
                      right: 10,
                      child: FavoriteIconButton(salonId: salon.id),
                    ),

                    // Details
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  salon.salonName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: compact ? 14.5 : 16.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (salon.isApproved) ...[
                                const SizedBox(width: 5),
                                const Icon(
                                  CupertinoIcons.checkmark_seal_fill,
                                  size: 15,
                                  color: Color(0xFF8FE3C9),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.location_solid,
                                size: 11,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  salon.district ?? salon.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: compact ? 11 : 12,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (category != null || (hasHours && !compact)) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (category != null)
                                  Flexible(
                                    child: ClientPill(
                                      label: category,
                                      color: Colors.white,
                                      onDark: true,
                                    ),
                                  ),
                                if (category != null && hasHours && !compact)
                                  const SizedBox(width: 6),
                                if (hasHours && !compact)
                                  ClientPill(
                                    label:
                                        '${salon.openingTime} – ${salon.closingTime}',
                                    color: Colors.white,
                                    icon: CupertinoIcons.clock,
                                    onDark: true,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
