import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

import '../../../../shared/models/category_data.dart';
import '../bloc/discovery_bloc.dart';
import '../bloc/discovery_event.dart';
import '../bloc/discovery_state.dart';

class FilterPanel extends StatefulWidget {
  const FilterPanel({super.key});

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel>
    with SingleTickerProviderStateMixin {
  String? _selectedCategoryId;
  double? _selectedMinRating;
  SortType _selectedSortType = SortType.popularity;
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    final state = context.read<DiscoveryBloc>().state;
    if (state is DiscoveryLoaded) {
      _selectedCategoryId = state.filters.categoryId;
      _selectedMinRating = state.filters.minRating;
      _selectedSortType = state.filters.sortType;
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 640, maxHeight: maxHeight),
          child: Container(
            decoration: BoxDecoration(
              color: ClientTheme.card(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'client.discover.filter.title'.tr(),
                            style: ClientTheme.title(context)
                                .copyWith(fontSize: 22),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _resetFilters,
                          icon: const Icon(CupertinoIcons.arrow_counterclockwise,
                              size: 16),
                          label: Text('client.discover.filter.reset'.tr()),
                          style: TextButton.styleFrom(
                            foregroundColor: ClientTheme.isDark(context)
                                ? cs.primary
                                : AppColors.primaryDark,
                            textStyle: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(
                              'client.discover.filter.category'.tr()),
                          _buildCategoryChips(),
                          const SizedBox(height: 26),
                          _sectionTitle(
                              'client.discover.filter.min_rating'.tr()),
                          _buildRatingFilter(),
                          const SizedBox(height: 26),
                          _sectionTitle('client.discover.filter.sort_by'.tr()),
                          _buildSortOptions(),
                        ],
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    decoration: BoxDecoration(
                      color: ClientTheme.card(context),
                      border: Border(
                        top: BorderSide(color: ClientTheme.border(context)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ClientTheme.textPrimary(context),
                              minimumSize: const Size(0, 52),
                              side: BorderSide(
                                color: ClientTheme.border(context),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text('common.cancel'.tr()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _applyFilters,
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              minimumSize: const Size(0, 52),
                              elevation: 0,
                              textStyle: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text('client.discover.filter.apply'.tr()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title.toUpperCase(), style: ClientTheme.label(context)),
      );

  // ── category ──────────────────────────────────────────────────────────────

  Widget _buildCategoryChips() {
    final categories = CategoriesData.allCategories;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          label: 'client.discover.filter.all_categories'.tr(),
          isSelected: _selectedCategoryId == null,
          onTap: () => setState(() => _selectedCategoryId = null),
        ),
        for (final category in categories)
          _Chip(
            label: 'categories.${category.name}'.tr(),
            isSelected: _selectedCategoryId == category.id,
            onTap: () => setState(() => _selectedCategoryId = category.id),
          ),
      ],
    );
  }

  // ── rating ────────────────────────────────────────────────────────────────

  Widget _buildRatingFilter() {
    const ratings = [1.0, 2.0, 3.0, 4.0, 4.5];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          label: 'client.discover.filter.any_rating'.tr(),
          isSelected: _selectedMinRating == null,
          onTap: () => setState(() => _selectedMinRating = null),
        ),
        for (final rating in ratings)
          _Chip(
            label: '$rating+',
            icon: CupertinoIcons.star_fill,
            isSelected: _selectedMinRating == rating,
            onTap: () => setState(() => _selectedMinRating = rating),
          ),
      ],
    );
  }

  // ── sort ──────────────────────────────────────────────────────────────────

  Widget _buildSortOptions() {
    return Column(
      children: [
        for (final sortType in SortType.values)
          _SortOption(
            sortType: sortType,
            isSelected: _selectedSortType == sortType,
            onTap: () => setState(() => _selectedSortType = sortType),
          ),
      ],
    );
  }

  void _applyFilters() {
    context.read<DiscoveryBloc>().add(
      ApplyFilters(
        categoryId: _selectedCategoryId,
        minRating: _selectedMinRating,
        sortType: _selectedSortType,
      ),
    );
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedMinRating = null;
      _selectedSortType = SortType.popularity;
    });
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ink = isSelected
        ? (ClientTheme.isDark(context) ? cs.primary : AppColors.primaryDark)
        : ClientTheme.textPrimary(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primary.withValues(alpha: 0.14)
            : ClientTheme.card(context),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isSelected ? cs.primary : ClientTheme.border(context),
          width: isSelected ? 1.6 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: const Color(0xFFF5A623)),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final SortType sortType;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.sortType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final IconData icon;
    final String description;
    switch (sortType) {
      case SortType.popularity:
        icon = CupertinoIcons.graph_square_fill;
        description = 'client.discover.filter.sort_popularity_desc'.tr();
        break;
      case SortType.rating:
        icon = CupertinoIcons.star_fill;
        description = 'client.discover.filter.sort_rating_desc'.tr();
        break;
      case SortType.newest:
        icon = CupertinoIcons.sparkles;
        description = 'client.discover.filter.sort_newest_desc'.tr();
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected
            ? cs.primary.withValues(alpha: 0.10)
            : ClientTheme.card(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isSelected ? cs.primary : ClientTheme.border(context),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    color: isSelected ? null : cs.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: isSelected ? Colors.white : cs.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sortType.displayName,
                        style: ClientTheme.heading(context),
                      ),
                      const SizedBox(height: 2),
                      Text(description, style: ClientTheme.caption(context)),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? cs.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? cs.primary : ClientTheme.border(context),
                      width: 1.8,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(CupertinoIcons.checkmark,
                          size: 12, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
