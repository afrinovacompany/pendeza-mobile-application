import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';
import 'package:pendeza/shared/widgets/salon_card.dart';

import '../../../../app/services/service_locator.dart';

import '../../../../shared/models/category_data.dart';
import '../../../0_auth/presentation/bloc/auth_bloc.dart';
import '../../../0_auth/presentation/bloc/auth_state.dart';
import '../../../../app/services/guest_session_tracker.dart';
import '../../../../app/services/local_storage_service.dart';
import '../../../../app/utils/navigation_guard.dart';

import '../bloc/discovery_bloc.dart';
import '../bloc/discovery_event.dart';
import '../bloc/discovery_state.dart';
import '../widgets/filter_panel.dart';

class DiscoveryScreen extends StatefulWidget {
  final String? initialCategoryId;

  const DiscoveryScreen({
    super.key,
    this.initialCategoryId,
  });

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> with NavigationGuard {
  final TextEditingController _searchController = TextEditingController();
  String? _lastRouteCategory;

  late final GuestSessionTracker _sessionTracker;
  late final LocalStorageService _localStorage;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _sessionTracker = sl<GuestSessionTracker>();
    _localStorage = sl<LocalStorageService>();
    final authState = context.read<AuthBloc>().state;
    _isGuest = authState is GuestMode;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    final fromRoute = extra is String && extra.isNotEmpty
        ? extra
        : widget.initialCategoryId;

    if (fromRoute != _lastRouteCategory) {
      _lastRouteCategory = fromRoute;
      if (fromRoute != null) {
        context.read<DiscoveryBloc>().add(FilterByCategory(fromRoute));
        return;
      }
    }

    final state = context.read<DiscoveryBloc>().state;
    if (state is DiscoveryInitial) {
      context.read<DiscoveryBloc>().add(const LoadSalons());
    }
  }

  @override
  void didUpdateWidget(DiscoveryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != oldWidget.initialCategoryId &&
        widget.initialCategoryId != null) {
      context.read<DiscoveryBloc>().add(
            FilterByCategory(widget.initialCategoryId),
          );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    context.read<DiscoveryBloc>().add(SearchSalons(query));

    if (_isGuest && query.isNotEmpty) {
      if (query.length > 2) {
        _sessionTracker.trackSearch(query);
        _localStorage.addToSearchHistory(query);
      }
    }
  }

  void _handleCategoryFilter(String? categoryId) {
    context.read<DiscoveryBloc>().add(FilterByCategory(categoryId));

    if (_isGuest && categoryId != null) {
      _sessionTracker.trackFeatureInteraction('category_filter');
    }
  }

  void _openFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterPanel(),
    );
  }

  /// Clears the search text and every filter.
  void _clearEverything() {
    _searchController.clear();
    _handleSearch('');
    context.read<DiscoveryBloc>().add(
          const ApplyFilters(
            categoryId: null,
            minRating: null,
            sortType: SortType.popularity,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientTheme.background(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            _buildCategoryChips(context),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
                builder: (context, state) {
                  if (state is DiscoveryLoading) {
                    return _buildLoadingGrid();
                  }

                  if (state is DiscoveryError) {
                    return ClientEmptyState(
                      icon: CupertinoIcons.wifi_exclamationmark,
                      color: Theme.of(context).colorScheme.error,
                      title: 'common.oops'.tr(),
                      message: state.message,
                      actionLabel: 'common.retry'.tr(),
                      onAction: () {
                        context.read<DiscoveryBloc>().add(const LoadSalons());
                      },
                    );
                  }

                  if (state is DiscoveryLoaded) {
                    if (state.filteredSalons.isEmpty) {
                      return ClientEmptyState(
                        icon: CupertinoIcons.search,
                        title: 'client.discover.no_results_title'.tr(),
                        message: 'client.discover.no_results'.tr(),
                        actionLabel: 'client.discover.clear_filters'.tr(),
                        onAction: _clearEverything,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<DiscoveryBloc>().add(const RefreshSalons());
                      },
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          ClientTheme.gutter,
                          8,
                          ClientTheme.gutter,
                          110,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: state.filteredSalons.length,
                        itemBuilder: (context, index) {
                          final salon = state.filteredSalons[index];
                          return TweenAnimationBuilder<double>(
                            duration: Duration(
                              milliseconds: 200 + ((index % 8) * 50),
                            ),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: SalonCard(
                              salon: salon,
                              onTap: () => _navigateToSalonDetail(salon),
                            ),
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientTheme.gutter,
        18,
        ClientTheme.gutter,
        14,
      ),
      child: Column(
        children: [
          // Title + result count
          Row(
            children: [
              Expanded(
                child: Text(
                  'client.discover.title'.tr(),
                  style: ClientTheme.display(context),
                ),
              ),
              BlocBuilder<DiscoveryBloc, DiscoveryState>(
                builder: (context, state) {
                  if (state is! DiscoveryLoaded) return const SizedBox.shrink();
                  return TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 350),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: ClientPill(
                      label: '${state.filteredSalons.length}',
                      color: cs.primary,
                      icon: CupertinoIcons.building_2_fill,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search + filter button
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: ClientTheme.card(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: ClientTheme.border(context)),
                      boxShadow: ClientTheme.shadow(context),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _handleSearch,
                      textInputAction: TextInputAction.search,
                      cursorColor: cs.primary,
                      style: ClientTheme.body(context),
                      decoration: InputDecoration(
                        hintText: 'client.discover.search_hint'.tr(),
                        hintStyle: ClientTheme.body(context).copyWith(
                          color: ClientTheme.textSecondary(context)
                              .withValues(alpha: 0.8),
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          CupertinoIcons.search,
                          color: ClientTheme.textSecondary(context),
                          size: 20,
                        ),
                        suffixIcon: value.text.isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  size: 18,
                                  color: ClientTheme.textSecondary(context),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _handleSearch('');
                                },
                              ),
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _FilterButton(onTap: _openFilterPanel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    return SizedBox(
      height: 46,
      child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
        buildWhen: (previous, current) {
          final prevId = previous is DiscoveryLoaded ? previous.filters.categoryId : null;
          final currId = current is DiscoveryLoaded ? current.filters.categoryId : null;
          return prevId != currId;
        },
        builder: (context, state) {
          final selectedId =
              state is DiscoveryLoaded ? state.filters.categoryId : null;

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
            itemCount: CategoriesData.allCategories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _CategoryChip(
                  label: 'client.discover.all'.tr(),
                  isSelected: selectedId == null,
                  onTap: () => _handleCategoryFilter(null),
                );
              }

              final category = CategoriesData.allCategories[index - 1];
              return _CategoryChip(
                label: 'categories.${category.name}'.tr(),
                isSelected: selectedId == category.id,
                onTap: () => _handleCategoryFilter(category.id),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        ClientTheme.gutter,
        8,
        ClientTheme.gutter,
        0,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) =>
              Opacity(opacity: value, child: child),
          child: ShimmerPlaceholder.rectangular(
            height: 200,
            borderRadius: BorderRadius.circular(26),
          ),
        );
      },
    );
  }

  void _navigateToSalonDetail(SalonModel salon) {
    guardedNavigate(() {
      if (_isGuest) {
        _sessionTracker.trackSalonView(salon.id);
        _localStorage.addToBrowsingHistory(salon.id);
      }

      context.push(
        AppRoutes.salonDetail.replaceFirst(':salonId', salon.id),
      );
    });
  }
}

/// Filter button with a badge showing how many filters are active.
class _FilterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      builder: (context, state) {
        final active = state is DiscoveryLoaded ? state.activeFilterCount : 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onTap,
                  child: const SizedBox(
                    width: 54,
                    height: 54,
                    child: Icon(
                      CupertinoIcons.slider_horizontal_3,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            if (active > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ClientTheme.background(context),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '$active',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: isSelected ? AppColors.primaryGradient : null,
        color: isSelected ? null : ClientTheme.card(context),
        borderRadius: BorderRadius.circular(100),
        border: isSelected
            ? null
            : Border.all(color: ClientTheme.border(context)),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                  spreadRadius: -3,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : ClientTheme.textPrimary(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
