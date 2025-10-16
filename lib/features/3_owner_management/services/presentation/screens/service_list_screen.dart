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
import 'package:pendeza/shared/widgets/custom_card.dart';
import 'package:pendeza/shared/widgets/empty_state_widget.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';

class ServiceListScreen extends StatelessWidget {
  const ServiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No initState needed, as the ShellRoute's BlocProvider handles the initial fetch.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Services'),
      ),
      body: BlocBuilder<ServicesBloc, ServicesState>(
        builder: (context, state) {
          if (state is ServicesLoading || state is ServicesInitial) {
            return _buildLoadingState();
          }
          if (state is ServicesError) {
            return EmptyStateWidget.error(
              message: state.message,
              onActionPressed: () =>
                  context.read<ServicesBloc>().add(FetchServicesRequested()),
            );
          }
          if (state is ServicesLoadSuccess) {
            if (state.services.isEmpty) {
              return const EmptyStateWidget.notFound(
                message:
                "You haven't added any services yet. Tap the '+' button to get started.",
              );
            }
            return _buildServicesList(context, state.services);
          }
          return const Center(child: Text("Something went wrong."));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(
            '${AppRoutes.ownerServices}/${AppRoutes.addEditService}',
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.padL),
      itemCount: 4,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: AppConstants.padM),
        child: ShimmerPlaceholder(height: 80, width: double.infinity),
      ),
    );
  }

  Widget _buildServicesList(BuildContext context, List<ServiceModel> services) {
    services.sort((a, b) => a.name.compareTo(b.name));

    // --- CHANGE IS HERE: Use RefreshIndicator ---
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ServicesBloc>().add(FetchServicesRequested());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.padL),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.padM),
            child: _ServiceListItem(service: service),
          );
        },
      ),
    );
  }
}

class _ServiceListItem extends StatelessWidget {
  const _ServiceListItem({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomCard(
      onTap: () {
        context.push(
          '${AppRoutes.ownerServices}/${AppRoutes.addEditService}',
          extra: service,
        );
      },
      child: Row(
        children: [
          Icon(CupertinoIcons.scissors,
              color: theme.colorScheme.primary, size: 30),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${service.durationMinutes} min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.padS),
          Text(
            AppFormatters.formatCurrency(service.price),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
