import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';

import '../../domain/models/regular_client.dart';
import '../bloc/client_management_bloc_new.dart';
import '../bloc/client_management_event_new.dart';
import '../bloc/client_management_state_new.dart';
import '../widgets/client_search_bar_new.dart';
import '../widgets/client_quick_view_bottom_sheet.dart';
import '../widgets/recent_bookings_section.dart';
import '../widgets/regular_clients_section.dart';


/// Simplified Client Management
///
/// Three sections:
/// 1. Search bar (sticky)
/// 2. Regular Clients (horizontal scroll, top 8)
/// 3. Recent Bookings (last 10 appointments)
class ClientManagementScreen extends StatelessWidget {
  const ClientManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ClientManagementBloc(
        repository: context.read(),
        firestoreService: context.read(),
        authBloc: context.read(),
      )..add(const LoadClients()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Clients'),
          centerTitle: true,
          elevation: 0,
        ),
        body: BlocBuilder<ClientManagementBloc, ClientManagementState>(
          builder: (context, state) {
            if (state is ClientManagementLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ClientManagementError) {
              return _buildError(context, state.message);
            }

            if (state is ClientManagementLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ClientManagementBloc>().add(const RefreshClients());
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: state.isSearching
                    ? _ClientSearchResults(results: state.searchResults!)
                    : _buildMainContent(context, state),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, ClientManagementLoaded state) {
    return CustomScrollView(
      slivers: [
        // Search bar (sticky)
        const SliverToBoxAdapter(
          child: ClientSearchBar(),
        ),

        // Regular Clients section
        if (state.regularClients.isNotEmpty)
          SliverToBoxAdapter(
            child: RegularClientsSection(clients: state.regularClients),
          ),

        // Spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: AppConstants.padL),
        ),

        // Recent Bookings section
        SliverToBoxAdapter(
          child: RecentBookingsSection(bookings: state.recentBookings),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: AppConstants.padXL),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: theme.colorScheme.error.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.padL),
            Text(
              'Oops!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.padS),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppConstants.padL),
            FilledButton.icon(
              onPressed: () {
                context.read<ClientManagementBloc>().add(const LoadClients());
              },
              icon: const Icon(CupertinoIcons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search results list — shows matching clients
class _ClientSearchResults extends StatelessWidget {
  final List<RegularClient> results;

  const _ClientSearchResults({required this.results});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // Search bar stays at the top
        const SliverToBoxAdapter(
          child: ClientSearchBar(),
        ),

        if (results.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.search,
                    size: 48,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: AppConstants.padM),
                  Text(
                    'No clients found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.padS),
                  Text(
                    'Try a different name or phone number',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final client = results[index];
                  return _SearchResultItem(client: client);
                },
                childCount: results.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final RegularClient client;

  const _SearchResultItem({required this.client});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ClientQuickViewBottomSheet(client: client),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.padM),
        padding: const EdgeInsets.all(AppConstants.padM),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            ProfileAvatar(
              fullName: client.name,
              imageUrl: client.photoUrl,
              radius: 24,
            ),
            const SizedBox(width: AppConstants.padM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (client.phone != null)
                    Text(
                      client.phone!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${client.visitCount} visits',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  client.lastVisitFormatted,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}