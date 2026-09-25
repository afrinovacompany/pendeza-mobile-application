import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';
import 'package:pendeza/shared/widgets/service_category_icon.dart';

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
  final List<ServiceModel> services;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final ValueChanged<ServiceModel>? onServiceTap;

  const SalonServicesTab({
    super.key,
    required this.salon,
    required this.services,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.onServiceTap,
  });

  @override
  State<SalonServicesTab> createState() => _SalonServicesTabState();
}

class _SalonServicesTabState extends State<SalonServicesTab> {
  // Track expanded categories
  final Set<String> _expandedCategories = {};

  List<ServiceModel> get _services => widget.services;

  @override
  void initState() {
    super.initState();
    _expandedCategories.addAll(_getCategories());
  }

  @override
  void didUpdateWidget(SalonServicesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.services != widget.services &&
        widget.services.isNotEmpty &&
        _expandedCategories.isEmpty) {
      _expandedCategories.addAll(_getCategories());
    }
  }

  List<ServiceModel> get _featuredServices {
    return _services.where((s) => s.isFeatured || s.isPopular).toList()
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
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.error != null) {
      return _buildErrorState();
    }

    if (_services.isEmpty) {
      return _buildEmptyState();
    }

    final featured = _featuredServices;

    return RefreshIndicator(
      onRefresh: () async => widget.onRetry?.call(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Services Carousel
            if (featured.isNotEmpty) ...[
              _buildFeaturedSection(featured),
              const SizedBox(height: 22),
            ],

            // Categorized Services
            ..._buildCategorySections(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(List<ServiceModel> featured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClientSectionHeader(
          title: 'client.salon_details.featured_services'.tr(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: FeaturedServiceCard.height + 18,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              ClientTheme.gutter,
              0,
              ClientTheme.gutter,
              18,
            ),
            itemCount: featured.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final service = featured[index];
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
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        ClientTheme.gutter,
        12,
        ClientTheme.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerPlaceholder(height: 22, width: 150),
          const SizedBox(height: 12),
          SizedBox(
            height: FeaturedServiceCard.height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => const ShimmerPlaceholder(
                height: FeaturedServiceCard.height,
                width: FeaturedServiceCard.width,
              ),
            ),
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < 3; i++) ...[
            const ShimmerPlaceholder(height: 88, width: double.infinity),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: ClientEmptyState(
          icon: CupertinoIcons.exclamationmark_circle,
          title: 'client.salon_details.failed_services'.tr(),
          actionLabel: 'client.salon_details.try_again'.tr(),
          onAction: widget.onRetry,
          color: const Color(0xFFEF4444),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: ClientEmptyState(
          icon: CupertinoIcons.scissors,
          title: 'client.salon_details.no_services'.tr(),
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
    final tone = ClientPalette.forKey(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClientTheme.gutter,
              vertical: 10,
            ),
            child: Row(
              children: [
                ClientIconTile(
                  icon: serviceCategoryIcon(category),
                  color: tone,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTheme.heading(context),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: ClientTheme.inset(context),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${services.length}',
                    style: ClientTheme.caption(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: AppConstants.durationFast,
                  child: Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: ClientTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Services List with Animation
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(
              ClientTheme.gutter,
              2,
              ClientTheme.gutter,
              8,
            ),
            child: Column(
              children: [
                for (final service in services)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ServiceCard(
                      service: service,
                      onTap: () => onServiceTap?.call(service),
                    ),
                  ),
              ],
            ),
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: AppConstants.durationMedium,
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}
