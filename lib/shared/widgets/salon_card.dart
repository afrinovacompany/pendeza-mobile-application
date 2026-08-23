import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/utils/placeholder_images.dart';
import 'package:pendeza/features/2_client_favorites/presentation/widgets/favorite_icon_button.dart';

import '../../app/config/theme/app_constants.dart';

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

  /// Builds the salon image with fallback to a placeholder when the primary
  /// image URL is empty, null, or fails to load from the network.
  Widget _buildSalonImage(ColorScheme colorScheme) {
    final primaryUrl = widget.salon.primaryImage ?? '';
    final fallbackUrl = PlaceholderImages.forSalon(widget.salon.id);

    // If no primary image at all, go straight to fallback
    if (primaryUrl.isEmpty) {
      return CachedNetworkImage(
        imageUrl: fallbackUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: colorScheme.surfaceContainerHighest,
          child: const Center(child: CupertinoActivityIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: colorScheme.surfaceContainerHighest,
          child: Icon(CupertinoIcons.photo, color: colorScheme.onSurface.withValues(alpha: 0.45)),
        ),
      );
    }

    // Try primary image, fall back to placeholder on error
    return CachedNetworkImage(
      imageUrl: primaryUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CupertinoActivityIndicator(),
      ),
      errorWidget: (context, url, error) => CachedNetworkImage(
        imageUrl: fallbackUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: colorScheme.surfaceContainerHighest,
          child: const Center(child: CupertinoActivityIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: colorScheme.surfaceContainerHighest,
          child: Icon(CupertinoIcons.photo, color: colorScheme.onSurface.withValues(alpha: 0.45)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            color: colorScheme.surface,
            borderRadius: AppConstants.radiusL,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image Section (Now Expanded to prevent vertical overflow)
              Expanded(
                flex: 3, // Takes 3 parts of the height
                child: Stack(
                  children: [
                    Hero(
                      tag: 'salon_image_${widget.salon.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppConstants.radiusValL),
                        ),
                        child: _buildSalonImage(colorScheme),
                      ),
                    ),
                    // Gradient overlay for better text contrast
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Favorite button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: FavoriteIconButton(salonId: widget.salon.id),
                    ),
                  ],
                ),
              ),

              // 2. Info Section (Fixed flex or specific height to prevent overflow)
              Expanded(
                flex: 2, // Takes 2 parts of the height
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.padS),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name and verification
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.salon.salonName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                color: colorScheme.primary,
                                size: 12,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // Location row
                          Row(
                            children: [
                              Icon(CupertinoIcons.location_solid,
                                  size: 10,
                                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.salon.district ?? widget.salon.address,
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Bottom row - rating and price level
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(CupertinoIcons.star_fill,
                                  color: colorScheme.tertiary,
                                  size: 12
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "4.8",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'TSh',
                            style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold
                            ),
                          ),
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
}