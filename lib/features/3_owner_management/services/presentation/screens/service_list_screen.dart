import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/bloc/services_bloc.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/bloc/services_event.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/bloc/services_state.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/shared/widgets/empty_state_widget.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';

class ServiceListScreen extends StatelessWidget {
  const ServiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('owner.services.title'.tr()),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                CupertinoIcons.add_circled_solid,
                color: Theme.of(context).colorScheme.primary,
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
        },
        child: BlocBuilder<ServicesBloc, ServicesState>(
          builder: (context, state) {
            if (state is ServicesLoading || state is ServicesInitial) {
              return _buildLoadingState();
            }
            if (state is ServicesError) {
              if (state is! ServicesLoadSuccess) {
                return EmptyStateWidget.error(
                  message: state.message,
                  onActionPressed: () =>
                      context.read<ServicesBloc>().add(FetchServicesRequested()),
                );
              }
            }

            if (state is ServicesLoadSuccess) {
              if (state.services.isEmpty) {
                return EmptyStateWidget.notFound(
                  message: 'owner.services.empty_msg'.tr(),
                );
              }
              return _buildServicesList(context, state.services,
                  isLoading: state is ServiceOperationInProgress);
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
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

  Widget _buildServicesList(BuildContext context, List<ServiceModel> services,
      {bool isLoading = false}) {
    services.sort((a, b) => a.name.compareTo(b.name));

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            context.read<ServicesBloc>().add(FetchServicesRequested());
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.padL),
            itemCount: services.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 80)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.padM),
                  child: _ServiceListItem(service: services[index]),
                ),
              );
            },
          ),
        ),
        if (isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

class _ServiceListItem extends StatelessWidget {
  const _ServiceListItem({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
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
            padding: const EdgeInsets.all(AppConstants.padL),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(14),
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
                  ),
                  child: Icon(
                    CupertinoIcons.scissors,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppConstants.padM),

                // 🔥 FIXED: Wrapped in Expanded to prevent overflow
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Name - 🔥 ADDED maxLines and overflow
                      Text(
                        service.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1, // 🔥 PREVENT OVERFLOW
                        overflow: TextOverflow.ellipsis, // 🔥 SHOW ...
                      ),
                      const SizedBox(height: 4),

                      // 🔥 FIXED: Wrapped Row in Flexible + added proper constraints
                      Row(
                        children: [
                          // Duration Chip
                          Flexible( // 🔥 ALLOW SHRINKING
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.time,
                                    size: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  // 🔥 ADDED Flexible to text
                                  Flexible(
                                    child: Text(
                                      '${service.durationMinutes} ${'common.min'.tr()}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis, // 🔥 PREVENT OVERFLOW
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Spacing between chips
                          if (service.category.isNotEmpty)
                            const SizedBox(width: 8),

                          // Category Chip - 🔥 WRAPPED IN FLEXIBLE
                          if (service.category.isNotEmpty)
                            Flexible( // 🔥 ALLOW SHRINKING
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  service.category,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1, // 🔥 PREVENT OVERFLOW
                                  overflow: TextOverflow.ellipsis, // 🔥 SHOW ...
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppConstants.padS),

                // Price Badge - 🔥 KEEP FIXED SIZE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green,
                        Colors.green.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    AppFormatters.formatCurrency(service.price),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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