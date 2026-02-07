import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';
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
  bool _isPressed = false;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _scaleController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) => Transform.scale(
          scale: 1.0 - (_scaleController.value * 0.03),
          child: child,
        ),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusValXL),
            boxShadow: _isPressed
                ? []
                : [
              BoxShadow(
                color: isDark ? Colors.black54 : Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(theme),
              Expanded(child: _buildInfoSection(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1.25,
          child: CachedNetworkImage(
            imageUrl: widget.salon.primaryImage ?? '',
            fit: BoxFit.cover,
            placeholder: (context, url) => const ShimmerPlaceholder.rectangular(height: double.infinity),
            errorWidget: (context, url, error) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(CupertinoIcons.scissors, size: 32),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: FavoriteIconButton(salonId: widget.salon.id, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),  // Reduced padding from 10 to 8
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(  // Made flexible to adapt
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.salon.serviceCategories.isNotEmpty)
                  Text(
                    widget.salon.serviceCategories.first.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                // TITLE ROW WITH EXPANDED TO PREVENT HORIZONTAL OVERFLOW
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.salon.salonName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,  // Reduced from 13
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: theme.colorScheme.primary,
                      size: 12,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // LOCATION ROW
                Row(
                  children: [
                    const Icon(CupertinoIcons.location_solid, size: 10, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.salon.district ?? widget.salon.address,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),  // Reduced from 10
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(CupertinoIcons.star_fill, color: Color(0xFFFFB800), size: 12),
              const SizedBox(width: 4),
              Text(
                "4.8",
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              Text(
                '\$\$\$',
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}