import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/shared/widgets/custom_card.dart';
import '../../domain/models/client_stats.dart';

class FavoriteServicesWidget extends StatelessWidget {
  final ClientStats clientStats;

  const FavoriteServicesWidget({
    super.key,
    required this.clientStats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (clientStats.favoriteServices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Favorite Services',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.padM),
          _FavoriteServicesList(serviceIds: clientStats.favoriteServices),
        ],
      ),
    );
  }
}

class _FavoriteServicesList extends StatelessWidget {
  final List<String> serviceIds;

  const _FavoriteServicesList({required this.serviceIds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestoreService = sl<FirestoreService>();

    return FutureBuilder<List<ServiceModel>>(
      future: _fetchServices(firestoreService, serviceIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CustomCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.padL),
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final services = snapshot.data!;
        return Column(
          children: services
              .asMap()
              .entries
              .map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.padS),
            child: _FavoriteServiceItem(
              service: entry.value,
              rank: entry.key + 1,
            ),
          ))
              .toList(),
        );
      },
    );
  }

  Future<List<ServiceModel>> _fetchServices(
      FirestoreService firestoreService,
      List<String> serviceIds,
      ) async {
    final services = <ServiceModel>[];
    for (final serviceId in serviceIds) {
      try {
        final service = await firestoreService.getServiceDetails(serviceId);
        services.add(service);
      } catch (e) {
        continue;
      }
    }
    return services;
  }
}

class _FavoriteServiceItem extends StatelessWidget {
  final ServiceModel service;
  final int rank;

  const _FavoriteServiceItem({
    required this.service,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      padding: const EdgeInsets.all(AppConstants.padM),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(rank).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _getRankColor(rank),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.padM),

          // Service details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${service.durationMinutes} min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Service icon
          Icon(
            Icons.star_rounded,
            color: _getRankColor(rank),
            size: 24,
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[300]!;
      default:
        return Colors.grey;
    }
  }
}