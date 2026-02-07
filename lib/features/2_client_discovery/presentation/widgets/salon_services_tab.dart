import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/2_client_booking/domain/repositories/booking_repository.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';

import 'service_card.dart';

/// Complete services tab with featured carousel and collapsible category sections.
///
/// Features:
/// - Featured section: Horizontal scrollable carousel of featured/popular services
/// - Categorized sections: Collapsible sections grouped by category
/// - Loading shimmer state
/// - Empty state handling
class SalonServicesTab extends StatefulWidget {
  final SalonModel salon;
  final ValueChanged<ServiceModel>? onServiceTap;

  const SalonServicesTab({
    super.key,
    required this.salon,
    this.onServiceTap,
  });

  @override
  State<SalonServicesTab> createState() => _SalonServicesTabState();
}

class _SalonServicesTabState extends State<SalonServicesTab> {
  List<ServiceModel> _services = [];
  bool _isLoading = true;
  String? _error;

  // Track expanded categories
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final services =
          await sl<BookingRepository>().getServicesForSalon(widget.salon.id);

      if (mounted) {
        setState(() {
          _services = services.where((s) => s.isActive).toList();
          _isLoading = false;
          // Expand all categories by default
          _expandedCategories.addAll(_getCategories());
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  List<ServiceModel> get _featuredServices {
    return _services
        .where((s) => s.isFeatured || s.isPopular)
        .toList()
      ..sort((a, b) {
        // Featured first, then popular, then by bookings count
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        return b.bookingsCount.compareTo(a.bookingsCount);
      });
  }

  Set<String> _getCategories() {
    return _services.map((s) => s.category).toSet();
  }

  Map<String, List<ServiceModel>> get _servicesByCategory {
    final map = <String, List<ServiceModel>>{};
    for (final service in _services) {
      map.putIfAbsent(service.category, () => []).add(service);
    }
    // Sort services within each category by sort order, then name
    for (final list in map.values) {
      list.sort((a, b) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.compareTo(b.name);
      });
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_services.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _fetchServices,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Services Carousel
            if (_featuredServices.isNotEmpty) ...[
              _buildFeaturedSection(),
              const SizedBox(height: AppConstants.padL),
            ],

            // Categorized Services
            ..._buildCategorySections(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.star_fill,
                size: 18,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              Text(
                'Featured Services',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.padS),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppConstants.padL),
            itemCount: _featuredServices.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppConstants.padS),
            itemBuilder: (context, index) {
              final service = _featuredServices[index];
              return FeaturedServiceCard(
                service: service,
                onTap: () => widget.onServiceTap?.call(service),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCategorySections() {
    final categories = _servicesByCategory;
    final sortedCategories = categories.keys.toList()..sort();

    return sortedCategories.map((category) {
      final services = categories[category]!;
      final isExpanded = _expandedCategories.contains(category);

      return _CategorySection(
        category: category,
        services: services,
        isExpanded: isExpanded,
        onToggle: () {
          setState(() {
            if (isExpanded) {
              _expandedCategories.remove(category);
            } else {
              _expandedCategories.add(category);
            }
          });
        },
        onServiceTap: widget.onServiceTap,
      );
    }).toList();
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.padL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured section shimmer
          const ShimmerPlaceholder(height: 24, width: 150),
          const SizedBox(height: AppConstants.padS),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppConstants.padS),
              itemBuilder: (context, index) => const ShimmerPlaceholder(
                height: 210,
                width: 180,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.padL),

          // Category sections shimmer
          for (var i = 0; i < 2; i++) ...[
            const ShimmerPlaceholder(height: 48, width: double.infinity),
            const SizedBox(height: AppConstants.padS),
            for (var j = 0; j < 3; j++) ...[
              const ShimmerPlaceholder(height: 90, width: double.infinity),
              const SizedBox(height: AppConstants.padS),
            ],
            const SizedBox(height: AppConstants.padM),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppConstants.padM),
            Text(
              'Failed to load services',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.padS),
            TextButton.icon(
              onPressed: _fetchServices,
              icon: const Icon(CupertinoIcons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.scissors,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppConstants.padM),
            Text(
              'client.salon_details.no_services'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A collapsible category section showing services.
class _CategorySection extends StatelessWidget {
  final String category;
  final List<ServiceModel> services;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<ServiceModel>? onServiceTap;

  const _CategorySection({
    required this.category,
    required this.services,
    required this.isExpanded,
    required this.onToggle,
    this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.padL,
                vertical: AppConstants.padS,
              ),
              child: Row(
                children: [
                  // Category Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppConstants.padS),

                  // Category Name
                  Expanded(
                    child: Text(
                      category,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Service Count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${services.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.padXS),

                  // Expand/Collapse Chevron
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: AppConstants.durationFast,
                    child: Icon(
                      CupertinoIcons.chevron_down,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Services List with Animation
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.padL,
            ),
            child: Column(
              children: services.map((service) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.padS),
                  child: ServiceCard(
                    service: service,
                    onTap: () => onServiceTap?.call(service),
                  ),
                );
              }).toList(),
            ),
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: AppConstants.durationMedium,
          sizeCurve: Curves.easeInOut,
        ),

        // Divider
        if (isExpanded)
          Divider(
            height: AppConstants.padL,
            indent: AppConstants.padL,
            endIndent: AppConstants.padL,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
      ],
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
    if (cat.contains('lash') || cat.contains('brow')) {
      return Icons.remove_red_eye;
    }
    if (cat.contains('men') || cat.contains('groom')) return Icons.content_cut;
    if (cat.contains('body') || cat.contains('spa')) return Icons.spa;
    if (cat.contains('tattoo') || cat.contains('piercing')) return Icons.edit;
    if (cat.contains('medical')) return Icons.medical_services;
    return CupertinoIcons.scissors;
  }
}
