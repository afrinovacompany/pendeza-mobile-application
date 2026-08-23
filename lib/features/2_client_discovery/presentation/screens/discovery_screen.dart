import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/empty_state_widget.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';
import 'package:pendeza/shared/widgets/salon_card.dart';

import '../../../../app/config/theme/app_constants.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced header
            _buildHeader(theme),
            // Category chips
            _buildCategoryChips(theme),
            const SizedBox(height: AppConstants.padM),
            // Grid view
            Expanded(
              child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
                builder: (context, state) {
                  if (state is DiscoveryLoading) {
                    return _buildLoadingGrid();
                  }

                  if (state is DiscoveryError) {
                    return EmptyStateWidget.error(
                      message: state.message,
                      onActionPressed: () {
                        context.read<DiscoveryBloc>().add(const LoadSalons());
                      },
                    );
                  }

                  if (state is DiscoveryLoaded) {
                    if (state.filteredSalons.isEmpty) {
                      return EmptyStateWidget.notFound(
                        message: 'client.discover.no_results'.tr(),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<DiscoveryBloc>().add(const RefreshSalons());
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.padL,
                          vertical: AppConstants.padS,
                        ),

                        // ... inside GridView.builder in discovery_screen.dart
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppConstants.padM,
                          mainAxisSpacing: AppConstants.padM,
                          // INCREASING the ratio to 0.68 - 0.7 gives more vertical room
                          childAspectRatio: 0.68,
                        ),
                        itemCount: state.filteredSalons.length,
                        itemBuilder: (context, index) {
                          final salon = state.filteredSalons[index];
                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 200 + (index * 50)),
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

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title row with count badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'client.discover.title'.tr(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              BlocBuilder<DiscoveryBloc, DiscoveryState>(
                builder: (context, state) {
                  if (state is DiscoveryLoaded) {
                    return TweenAnimationBuilder<double>(
                      duration: AppConstants.durationMedium,
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${state.filteredSalons.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),

          const SizedBox(height: AppConstants.padM),

          // Search bar with filter button
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _handleSearch,
                    decoration: InputDecoration(
                      hintText: 'client.discover.search_hint'.tr(),
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      prefixIcon: Icon(
                        CupertinoIcons.search,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.padM,
                        vertical: AppConstants.padM,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppConstants.padS),

              // Enhanced filter button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _openFilterPanel,
                  icon: const Icon(CupertinoIcons.slider_horizontal_3),
                  color: Colors.white,
                  iconSize: 20,
                  padding: const EdgeInsets.all(AppConstants.padM),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme) {
    return SizedBox(
      height: 44,
      child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
        buildWhen: (previous, current) {
          final prevId = previous is DiscoveryLoaded ? previous.filters.categoryId : null;
          final currId = current is DiscoveryLoaded ? current.filters.categoryId : null;
          return prevId != currId;
        },
        builder: (context, state) {
          final selectedId =
              state is DiscoveryLoaded ? state.filters.categoryId : null;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
            itemCount: CategoriesData.allCategories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppConstants.padS),
                  child: _buildCategoryChip(
                    theme: theme,
                    label: 'client.discover.all'.tr(),
                    isSelected: selectedId == null,
                    onTap: () => _handleCategoryFilter(null),
                  ),
                );
              }

              final category = CategoriesData.allCategories[index - 1];
              return Padding(
                padding: const EdgeInsets.only(right: AppConstants.padS),
                child: _buildCategoryChip(
                  theme: theme,
                  label: 'categories.${category.name}'.tr(),
                  isSelected: selectedId == category.id,
                  onTap: () => _handleCategoryFilter(category.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required ThemeData theme,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: AppConstants.durationFast,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.padL,
            vertical: AppConstants.padS,
          ),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.padL,
        vertical: AppConstants.padS,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppConstants.padM,
        mainAxisSpacing: AppConstants.padM,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: child,
            );
          },
          child: const ShimmerPlaceholder.rectangular(
            height: 200,
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