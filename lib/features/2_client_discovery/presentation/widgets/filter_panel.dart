import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/models/category_data.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
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
    final theme = Theme.of(context);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: AppConstants.padM),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppConstants.padL),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'client.discover.filter.title'.tr(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text('client.discover.filter.reset'.tr()),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.padL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(theme, 'client.discover.filter.category'.tr()),
                      const SizedBox(height: AppConstants.padM),
                      _buildCategoryChips(theme),
                      const SizedBox(height: AppConstants.padXXL),
                      _buildSectionTitle(theme, 'client.discover.filter.min_rating'.tr()),
                      const SizedBox(height: AppConstants.padM),
                      _buildRatingFilter(theme),
                      const SizedBox(height: AppConstants.padXXL),
                      _buildSectionTitle(theme, 'client.discover.filter.sort_by'.tr()),
                      const SizedBox(height: AppConstants.padM),
                      _buildSortOptions(theme),
                      const SizedBox(height: AppConstants.padXL),
                    ],
                  ),
                ),
              ),

              // Footer buttons
              Container(
                padding: const EdgeInsets.all(AppConstants.padL),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: theme.colorScheme.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('common.cancel'.tr()),
                      ),
                    ),
                    const SizedBox(width: AppConstants.padM),
                    Expanded(
                      flex: 2,
                      child: PrimaryGradientButton(
                        text: 'client.discover.filter.apply'.tr(),
                        onPressed: _applyFilters,
                      ),
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

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(ThemeData theme) {
    final categories = CategoriesData.allCategories;

    return Wrap(
      spacing: AppConstants.padS,
      runSpacing: AppConstants.padS,
      children: [
        _buildCategoryChip(
          theme: theme,
          label: 'client.discover.filter.all_categories'.tr(),
          isSelected: _selectedCategoryId == null,
          onTap: () => setState(() => _selectedCategoryId = null),
        ),
        ...categories.map((category) {
          final isSelected = _selectedCategoryId == category.id;
          return _buildCategoryChip(
            theme: theme,
            label: 'categories.${category.name}'.tr(),
            isSelected: isSelected,
            color: Color(category.color),
            onTap: () => setState(() => _selectedCategoryId = category.id),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryChip({
    required ThemeData theme,
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.padM + 2,
          vertical: AppConstants.padS + 2,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [chipColor, chipColor.withValues(alpha: 0.8)],
          )
              : null,
          color: isSelected ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: chipColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingFilter(ThemeData theme) {
    final ratings = [1.0, 2.0, 3.0, 4.0, 4.5];

    return Wrap(
      spacing: AppConstants.padS,
      runSpacing: AppConstants.padS,
      children: [
        _buildRatingChip(
          theme: theme,
          rating: null,
          label: 'client.discover.filter.any_rating'.tr(),
          isSelected: _selectedMinRating == null,
        ),
        ...ratings.map((rating) {
          return _buildRatingChip(
            theme: theme,
            rating: rating,
            isSelected: _selectedMinRating == rating,
          );
        }),
      ],
    );
  }

  Widget _buildRatingChip({
    required ThemeData theme,
    required double? rating,
    String? label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedMinRating = rating),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.padM + 2,
          vertical: AppConstants.padS + 2,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          )
              : null,
          color: isSelected ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rating != null) ...[
              Icon(
                Icons.star_rounded,
                size: 18,
                color: isSelected ? Colors.white : theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '$rating+',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ] else ...[
              Text(
                label ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSortOptions(ThemeData theme) {
    return Column(
      children: SortType.values.map((sortType) {
        return _buildSortOption(
          theme: theme,
          sortType: sortType,
          isSelected: _selectedSortType == sortType,
        );
      }).toList(),
    );
  }

  Widget _buildSortOption({
    required ThemeData theme,
    required SortType sortType,
    required bool isSelected,
  }) {
    IconData icon;
    String description;

    switch (sortType) {
      case SortType.popularity:
        icon = Icons.trending_up_rounded;
        description = 'client.discover.filter.sort_popularity_desc'.tr();
        break;
      case SortType.rating:
        icon = Icons.star_rounded;
        description = 'client.discover.filter.sort_rating_desc'.tr();
        break;
      case SortType.newest:
        icon = Icons.schedule_rounded;
        description = 'client.discover.filter.sort_newest_desc'.tr();
        break;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedSortType = sortType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: AppConstants.padS),
        padding: const EdgeInsets.all(AppConstants.padM),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.secondary.withValues(alpha: 0.05),
            ],
          )
              : null,
          color: isSelected ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.padS),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                )
                    : null,
                color: isSelected ? null : theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppConstants.padM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sortType.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                )
                    : null,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 2,
                ),
                color: isSelected ? null : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                child: Icon(Icons.check, size: 12, color: Colors.white),
              )
                  : null,
            ),
          ],
        ),
      ),
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