import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/shared/models/service_model.dart';

/// Vertical service card for category lists.
///
/// Displays:
/// - Service image or category icon (56x56)
/// - Name with "Popular" badge if `isPopular`
/// - Duration with clock icon
/// - Price with discount strikethrough if `hasDiscount`
/// - Selection state styling
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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        borderRadius: AppConstants.radiusM,
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.15),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppConstants.radiusM,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppConstants.radiusM,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.padM),
            child: Row(
              children: [
                // Service Image/Icon
                _buildServiceImage(context),
                const SizedBox(width: AppConstants.padM),

                // Service Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name + Popular Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              service.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (service.isPopular) ...[
                            const SizedBox(width: 6),
                            _buildBadge(
                              context,
                              'Popular',
                              Colors.orange,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Duration
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.time,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${service.durationMinutes} min',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppConstants.padS),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (service.hasDiscount) ...[
                      Text(
                        AppFormatters.formatCurrency(service.price),
                        style: theme.textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: service.hasDiscount
                            ? Colors.red.withValues(alpha: 0.1)
                            : theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: AppConstants.radiusS,
                      ),
                      child: Text(
                        AppFormatters.formatCurrency(service.effectivePrice),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: service.hasDiscount
                              ? Colors.red
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Selection Indicator
                if (isSelected) ...[
                  const SizedBox(width: AppConstants.padS),
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceImage(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.12),
                theme.colorScheme.secondary.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: service.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: CachedNetworkImage(
                    imageUrl: service.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    errorWidget: (context, url, error) => Icon(
                      _getCategoryIcon(service.category),
                      color: theme.colorScheme.primary,
                      size: 26,
                    ),
                  ),
                )
              : Icon(
                  _getCategoryIcon(service.category),
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
        ),
        // Discount badge
        if (service.hasDiscount)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '-${service.discountPercentage.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('hair')) return CupertinoIcons.scissors;
    if (cat.contains('nail')) return Icons.back_hand_outlined;
    if (cat.contains('massage')) return Icons.spa;
    if (cat.contains('skin') || cat.contains('facial')) return Icons.face;
    if (cat.contains('makeup') || cat.contains('beauty')) return Icons.brush;
    if (cat.contains('braid') || cat.contains('extension')) return Icons.person;
    if (cat.contains('lash') || cat.contains('brow')) return Icons.remove_red_eye;
    if (cat.contains('men') || cat.contains('groom')) return Icons.content_cut;
    if (cat.contains('body') || cat.contains('spa')) return Icons.spa;
    if (cat.contains('tattoo') || cat.contains('piercing')) return Icons.edit;
    if (cat.contains('medical')) return Icons.medical_services;
    return CupertinoIcons.scissors;
  }
}

/// Horizontal featured service card for carousel display.
///
/// Fixed 180px width for horizontal scroll with:
/// - Hero image area (100px height)
/// - "Featured" or "Popular" badge overlay
/// - Compact name, duration, price
class FeaturedServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;

  const FeaturedServiceCard({
    super.key,
    required this.service,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppConstants.radiusL,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppConstants.radiusL,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppConstants.radiusL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hero Image Area
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppConstants.radiusValL),
                    ),
                    child: SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: service.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: service.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      theme.colorScheme.secondary
                                          .withValues(alpha: 0.1),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  _getCategoryIcon(service.category),
                                  size: 32,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  _buildPlaceholder(context),
                            )
                          : _buildPlaceholder(context),
                    ),
                  ),

                  // Badge Overlay
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildOverlayBadge(context),
                  ),

                  // Discount Badge
                  if (service.hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${service.discountPercentage.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Content Area
              Padding(
                padding: const EdgeInsets.all(AppConstants.padS),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Name
                    Text(
                      service.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Duration
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.time,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${service.durationMinutes} min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Price Row
                    Row(
                      children: [
                        if (service.hasDiscount) ...[
                          Text(
                            AppFormatters.formatCurrency(service.price),
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          AppFormatters.formatCurrency(service.effectivePrice),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: service.hasDiscount
                                ? Colors.red
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.secondary.withValues(alpha: 0.15),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(service.category),
          size: 36,
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildOverlayBadge(BuildContext context) {
    final isFeatured = service.isFeatured;
    final color = isFeatured ? Colors.purple : Colors.orange;
    final text = isFeatured ? 'Featured' : 'Popular';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFeatured ? CupertinoIcons.star_fill : CupertinoIcons.flame_fill,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('hair')) return CupertinoIcons.scissors;
    if (cat.contains('nail')) return Icons.back_hand_outlined;
    if (cat.contains('massage')) return Icons.spa;
    if (cat.contains('skin') || cat.contains('facial')) return Icons.face;
    if (cat.contains('makeup') || cat.contains('beauty')) return Icons.brush;
    if (cat.contains('braid') || cat.contains('extension')) return Icons.person;
    if (cat.contains('lash') || cat.contains('brow')) return Icons.remove_red_eye;
    if (cat.contains('men') || cat.contains('groom')) return Icons.content_cut;
    if (cat.contains('body') || cat.contains('spa')) return Icons.spa;
    if (cat.contains('tattoo') || cat.contains('piercing')) return Icons.edit;
    if (cat.contains('medical')) return Icons.medical_services;
    return CupertinoIcons.scissors;
  }
}
