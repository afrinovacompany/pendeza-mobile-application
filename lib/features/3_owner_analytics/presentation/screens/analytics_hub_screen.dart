import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';

import 'package:pendeza/shared/widgets/custom_card.dart';
import 'package:collection/collection.dart'; // We keep this for .mapIndexed

import '../bloc/analytic_bloc.dart';
import '../bloc/analytic_event.dart';
import '../bloc/analytic_state.dart';

class AnalyticsHubScreen extends StatelessWidget {
  const AnalyticsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dispatch load event on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsBloc>().add(const LoadAnalyticsData());
    });

    return Scaffold(
      appBar: AppBar(
        // Key: "owner.analytics.title"
        title: Text('owner.analytics.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AnalyticsBloc>().add(const RefreshAnalyticsData()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<AnalyticsBloc>().add(const RefreshAnalyticsData());
        },
        child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
          builder: (context, state) {
            if (state is AnalyticsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AnalyticsError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: AppConstants.padM),
                    Text(state.message, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppConstants.padM),
                    ElevatedButton(
                      onPressed: () => context.read<AnalyticsBloc>().add(const LoadAnalyticsData()),
                      child: const Text('Retry'), // "Retry"
                    ),
                  ],
                ),
              );
            }

            if (state is AnalyticsLoaded) {
              return ListView(
                padding: const EdgeInsets.all(AppConstants.padL),
                children: [
                  _buildSectionTitle(context, 'Weekly Revenue', Icons.bar_chart),
                  const SizedBox(height: AppConstants.padS),
                  CustomCard(
                    child: SizedBox(
                      height: 250,
                      // --- USE PURE FLUTTER BAR CHART ---
                      child: _buildRevenueBarChart(context, state.weeklyRevenue),
                    ),
                  ),
                  const SizedBox(height: AppConstants.padXL),
                  _buildSectionTitle(context, 'Service Popularity', Icons.pie_chart),
                  const SizedBox(height: AppConstants.padS),
                  CustomCard(
                    child: SizedBox(
                      height: 250,
                      // --- USE PURE FLUTTER LIST ---
                      child: _buildServicePopularityList(context, state.servicePopularity),
                    ),
                  ),
                  const SizedBox(height: AppConstants.padXL),
                  _buildSectionTitle(context, 'Top Services', Icons.star),
                  const SizedBox(height: AppConstants.padS),
                  _buildTopServicesList(context, state.topServices),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: AppConstants.padM),
        Text(title, style: AppTextStyles.headline3.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- NEW: PURE FLUTTER BAR CHART ---
  Widget _buildRevenueBarChart(BuildContext context, List<double> weeklyRevenue) {
    final theme = Theme.of(context);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    if (weeklyRevenue.isEmpty) {
      return Center(
        child: Text('No revenue data yet', style: AppTextStyles.bodyMedium.copyWith(color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).round()))),
      );
    }

    // Find max revenue to normalize heights
    final maxRevenue = weeklyRevenue.reduce((a, b) => a > b ? a : b);
    if (maxRevenue == 0) {
      return Center(
        child: Text('No revenue data to display', style: AppTextStyles.bodyMedium.copyWith(color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).round()))),
      );
    }

    // This is the max height the bar itself can be, leaving space for labels
    const double chartHeight = 180;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.padM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weeklyRevenue.mapIndexed((index, revenue) {
          // Calculate proportional height
          final barHeight = (revenue / maxRevenue) * chartHeight;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // The bar
              AnimatedContainer(
                duration: AppConstants.durationMedium,
                width: 18, // Bar width
                height: barHeight < 5 ? 5 : barHeight, // Min height of 5px
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
              const SizedBox(height: AppConstants.padXS),
              // Day label
              Text(
                days[index],
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // --- NEW: PURE FLUTTER POPULARITY LIST ---
  Widget _buildServicePopularityList(BuildContext context, Map<String, int> servicePopularity) {
    final theme = Theme.of(context);
    final total = servicePopularity.values.fold(0, (sum, count) => sum + count);

    if (total == 0) {
      return Center(
        child: Text('No data yet', style: AppTextStyles.bodyMedium.copyWith(color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).round()))),
      );
    }

    final colors = [AppColors.primary, AppColors.accent, AppColors.success, AppColors.warning, AppColors.error];

    // Sort by most popular
    final sortedEntries = servicePopularity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(AppConstants.padM),
      children: sortedEntries.mapIndexed((index, entry) {
        final percentage = (entry.value / total);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.padM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service name and percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}% (${entry.value})',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.padXS),
              // Percentage Bar
              ClipRRect(
                borderRadius: AppConstants.radiusS,
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 12,
                  backgroundColor: theme.dividerColor.withAlpha(50),
                  color: colors[index % colors.length], // Cycle through colors
                  borderRadius: AppConstants.radiusS,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- This list view is fine, no changes needed ---
  Widget _buildTopServicesList(BuildContext context, List<MapEntry<String, int>> topServices) {
    final theme = Theme.of(context);
    if (topServices.isEmpty) {
      return CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padM),
          // Key: "owner.analytics.no_services"
          child: Text('owner.analytics.no_services'.tr(), style: AppTextStyles.bodyMedium.copyWith(color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).round()))),
        ),
      );
    }

    return CustomCard(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topServices.length,
        itemBuilder: (context, index) {
          final entry = topServices[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withAlpha((0.1 * 255).round()),
              child: Text('${index + 1}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
            ),
            title: Text(entry.key, style: AppTextStyles.bodyMedium),
            // Key: "owner.analytics.bookings_count"
            trailing: Text('${entry.value} ${'owner.analytics.bookings_count'.tr()}', style: AppTextStyles.caption.copyWith(color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()))),
          );
        },
      ),
    );
  }
}