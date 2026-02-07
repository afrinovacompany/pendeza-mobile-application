import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/bloc/services_bloc.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/bloc/services_event.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/bloc/services_state.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/shared/widgets/empty_state_widget.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String _sortBy = 'name'; // name, price, popular
  bool _showInactiveOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ServiceModel> _filterAndSortServices(List<ServiceModel> services) {
    var filtered = services.toList();

    // Filter by search
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((s) {
        return s.name.toLowerCase().contains(query) ||
            s.description.toLowerCase().contains(query) ||
            s.category.toLowerCase().contains(query) ||
            s.tags.any((t) => t.toLowerCase().contains(query));
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != null) {
      filtered = filtered.where((s) => s.category == _selectedCategory).toList();
    }

    // Filter by status
    if (_showInactiveOnly) {
      filtered = filtered.where((s) => !s.isActive).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'price':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'popular':
        filtered.sort((a, b) => b.bookingsCount.compareTo(a.bookingsCount));
        break;
      case 'duration':
        filtered.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
        break;
      default:
        filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    return filtered;
  }

  Set<String> _getCategories(List<ServiceModel> services) {
    return services.map((s) => s.category).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('owner.services.title'.tr()),
        actions: [
          // Sort Button
          PopupMenuButton<String>(
            icon: const Icon(CupertinoIcons.sort_down),
            tooltip: 'Sort',
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(_sortBy == 'name' ? Icons.check : null, size: 18),
                    const SizedBox(width: 8),
                    const Text('Name (A-Z)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price',
                child: Row(
                  children: [
                    Icon(_sortBy == 'price' ? Icons.check : null, size: 18),
                    const SizedBox(width: 8),
                    const Text('Price (Low-High)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price_desc',
                child: Row(
                  children: [
                    Icon(_sortBy == 'price_desc' ? Icons.check : null, size: 18),
                    const SizedBox(width: 8),
                    const Text('Price (High-Low)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'popular',
                child: Row(
                  children: [
                    Icon(_sortBy == 'popular' ? Icons.check : null, size: 18),
                    const SizedBox(width: 8),
                    const Text('Most Popular'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'duration',
                child: Row(
                  children: [
                    Icon(_sortBy == 'duration' ? Icons.check : null, size: 18),
                    const SizedBox(width: 8),
                    const Text('Duration'),
                  ],
                ),
              ),
            ],
          ),
          // Add Button
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                  theme.colorScheme.secondary.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                CupertinoIcons.add_circled_solid,
                color: theme.colorScheme.primary,
              ),
              onPressed: () {
                context.push('${AppRoutes.ownerServices}/${AppRoutes.addEditService}');
              },
            ),
          ),
        ],
      ),
      body: BlocListener<ServicesBloc, ServicesState>(
        listener: (context, state) {
          if (state is ServicesError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red));
          }
          if (state is ServiceOperationSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ));
          }
        },
        child: BlocBuilder<ServicesBloc, ServicesState>(
          builder: (context, state) {
            if (state is ServicesLoading || state is ServicesInitial) {
              return _buildLoadingState();
            }
            if (state is ServicesError && state is! ServicesLoadSuccess) {
              return EmptyStateWidget.error(
                message: state.message,
                onActionPressed: () =>
                    context.read<ServicesBloc>().add(FetchServicesRequested()),
              );
            }

            if (state is ServicesLoadSuccess) {
              return _buildContent(context, state.services);
            }

            if (state is ServiceOperationInProgress) {
              return _buildLoadingState();
            }

            return Center(child: Text('common.error_generic'.tr()));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('${AppRoutes.ownerServices}/${AppRoutes.addEditService}');
        },
        icon: const Icon(CupertinoIcons.add),
        label: const Text('Add Service'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<ServiceModel> services) {
    final theme = Theme.of(context);
    final categories = _getCategories(services);
    final filteredServices = _filterAndSortServices(services);
    final activeCount = services.where((s) => s.isActive).length;
    final inactiveCount = services.length - activeCount;

    return Column(
      children: [
        // Stats Bar
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.padL,
            vertical: AppConstants.padS,
          ),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Row(
            children: [
              _buildStatPill(
                '$activeCount Active',
                AppColors.success,
                !_showInactiveOnly,
                () => setState(() => _showInactiveOnly = false),
              ),
              const SizedBox(width: 8),
              _buildStatPill(
                '$inactiveCount Inactive',
                AppColors.warning,
                _showInactiveOnly,
                () => setState(() => _showInactiveOnly = true),
              ),
              const Spacer(),
              Text(
                '${filteredServices.length} shown',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        // Search & Filter Bar
        Padding(
          padding: const EdgeInsets.all(AppConstants.padM),
          child: Column(
            children: [
              // Search Field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  prefixIcon: const Icon(CupertinoIcons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.padM,
                    vertical: AppConstants.padS,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppConstants.padS),

              // Category Filter Chips
              if (categories.length > 1)
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip(
                        'All',
                        _selectedCategory == null,
                        () => setState(() => _selectedCategory = null),
                      ),
                      ...categories.map((cat) => _buildFilterChip(
                            cat,
                            _selectedCategory == cat,
                            () => setState(() => _selectedCategory = cat),
                          )),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Services List
        Expanded(
          child: filteredServices.isEmpty
              ? EmptyStateWidget.notFound(
                  message: _searchController.text.isNotEmpty
                      ? 'No services match your search'
                      : 'owner.services.empty_msg'.tr(),
                )
              : _buildServicesList(context, filteredServices),
        ),
      ],
    );
  }

  Widget _buildStatPill(String text, Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? color : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.padL),
      itemCount: 4,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: AppConstants.padM),
        child: ShimmerPlaceholder(height: 90, width: double.infinity),
      ),
    );
  }

  Widget _buildServicesList(BuildContext context, List<ServiceModel> services) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ServicesBloc>().add(FetchServicesRequested());
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.padL,
          0,
          AppConstants.padL,
          100, // Space for FAB
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 200 + (index * 50)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 15 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.padM),
              child: _ServiceListItem(
                service: services[index],
                onToggleActive: () {
                  context.read<ServicesBloc>().add(
                        ToggleServiceActiveRequested(services[index].id),
                      );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServiceListItem extends StatelessWidget {
  const _ServiceListItem({
    required this.service,
    required this.onToggleActive,
  });

  final ServiceModel service;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInactive = !service.isActive;

    return Opacity(
      opacity: isInactive ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInactive
                ? Colors.orange.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              context.push(
                '${AppRoutes.ownerServices}/${AppRoutes.addEditService}',
                extra: service,
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.padM),
              child: Row(
                children: [
                  // Icon/Image Container
                  Stack(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                              theme.colorScheme.secondary.withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          ),
                          image: service.imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(service.imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: service.imageUrl == null
                            ? Icon(
                                _getCategoryIcon(service.category),
                                color: theme.colorScheme.primary,
                                size: 26,
                              )
                            : null,
                      ),
                      // Popular badge
                      if (service.isPopular)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      // Inactive badge
                      if (isInactive)
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.pause,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppConstants.padM),

                  // Service Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                service.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: isInactive
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (service.isFeatured)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'FEATURED',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Duration Chip
                            _buildInfoChip(
                              CupertinoIcons.time,
                              '${service.durationMinutes} min',
                              theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            // Category Chip
                            if (service.category.isNotEmpty)
                              Flexible(
                                child: _buildInfoChip(
                                  CupertinoIcons.tag,
                                  service.category,
                                  Colors.purple,
                                ),
                              ),
                            // Bookings count
                            if (service.bookingsCount > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${service.bookingsCount} bookings',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade500,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppConstants.padS),

                  // Price & Actions Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Price
                      if (service.hasDiscount) ...[
                        Text(
                          AppFormatters.formatCurrency(service.price),
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
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
                          gradient: LinearGradient(
                            colors: service.hasDiscount
                                ? [Colors.red, Colors.red.shade700]
                                : [Colors.green, Colors.green.shade600],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: (service.hasDiscount
                                      ? Colors.red
                                      : Colors.green)
                                  .withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          AppFormatters.formatCurrency(service.effectivePrice),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Toggle Active Button
                      GestureDetector(
                        onTap: onToggleActive,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isInactive
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isInactive ? 'Activate' : 'Pause',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isInactive
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
